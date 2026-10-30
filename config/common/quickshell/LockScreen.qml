// wayland-desktop lock screens drawn by quickshell (the session lock of shell.qml)
//   shell (Terminal / better-tty): a fastfetch block (its image + the stats of the PC), then a "> " prompt: login (then
//          the password), switch <profile> (Tab completes), whoami, help... and a few commands for fun
//   getty (Dev / low level): the info of the Dev lock, then "login:" and "Password:" like a console
// The password goes to PAM ("hyprlock" config, the one of hyprlock); nothing else ever unlocks

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam

Item {
    id: lock

    required property string mode
    // the screen of this surface: the capture of the session taken by wd-style lock (Terminal)
    property string screenName: ""
    property string pamConfig: "hyprlock"
    property string pamDirectory: "/etc/pam.d"

    signal unlocked

    readonly property string home: Quickshell.env("HOME")
    readonly property string user: Quickshell.env("USER") || "user"
    readonly property string wdStyle: home + "/.local/bin/wd-style"
    readonly property bool shell: mode === "shell"
    // rose-pine (better-tty) or the phosphor green of Dev
    readonly property var c: shell ? {
        base: "#191724", surface: "#1f1d2e", text: "#e0def4", muted: "#6e6a86", subtle: "#908caa", accent: "#c4a7e7",
        good: "#9ccfd8", warn: "#f6c177", bad: "#eb6f92", key: "#c4a7e7", rose: "#ebbcba", pine: "#31748f"
    } : {
        base: "#040705", surface: "#0a1d12", text: "#b8f5cf", muted: "#4f9a6f", subtle: "#2f7a4f", accent: "#39ff88",
        good: "#4fd1ff", warn: "#ffb000", bad: "#ff4f5e", key: "#39ff88", rose: "#ffb000", pine: "#1c4a2e"
    }
    readonly property var commands: ["help", "login", "switch", "profiles", "whoami", "fastfetch", "date", "uptime",
        "music", "clear", "history", "echo", "cowsay", "fortune", "sl", "matrix", "hack", "sudo", "exit", "39", "suspend",
        "reboot", "poweroff"]
    readonly property var fortunes: ["There is no place like 127.0.0.1", "It works on my machine.",
        "sudo make me a sandwich", "A clean desk is a sign of a full trash bin.", "The cake is a lie.",
        "Real programmers count from 0.", "rm -rf / is not a backup strategy", "39 = san-kyu = thank you"]

    // transcript: {text, color}
    property var lines: []
    // command, password (shell); login, password (getty); busy while PAM works
    property string stage: shell ? "command" : "login"
    property string login: user
    property string secret: ""
    property var history: []
    property int back: -1
    property string confirm: ""
    property var info: ({})
    property var profiles: []
    property string profile: ""
    property string playing: ""
    property bool rain: false
    property real train: -1

    function say(text, color) {
        const next = lock.lines.concat(text.split("\n").map(t => ({ text: t, color: color || lock.c.text })));

        lock.lines = next.slice(-200);
    }

    function prompt() {
        if (lock.stage === "password")
            return lock.shell ? `password for ${lock.login}: ` : "Password: ";
        if (lock.stage === "login")
            return `${lock.info.host || "linux"} login: `;
        if (lock.stage === "busy")
            return "";
        return "> ";
    }

    // =========================
    // Authentication
    // =========================
    PamContext {
        id: pam

        config: lock.pamConfig
        configDirectory: lock.pamDirectory
        user: lock.login
        onPamMessage: {
            if (responseRequired) {
                respond(lock.secret);
                lock.secret = "";
            } else if (message) {
                lock.say(message, messageIsError ? lock.c.bad : lock.c.subtle);
            }
        }
        onCompleted: result => {
            lock.secret = "";
            if (result === PamResult.Success) {
                lock.say(lock.shell ? `welcome back, ${lock.login} \u266a` : `Last login: ${new Date().toString()} on tty1`,
                    lock.c.good);
                lock.stage = "busy";
                leave.start();
                return;
            }
            lock.say(lock.shell ? "authentication failed: try again (login)" : "\nLogin incorrect", lock.c.bad);
            lock.stage = lock.shell ? "command" : "login";
        }
        onError: error => {
            lock.secret = "";
            lock.say(`pam: ${PamError.toString(error)}`, lock.c.bad);
            lock.stage = lock.shell ? "command" : "login";
        }
    }

    Timer {
        id: leave

        interval: 450
        onTriggered: lock.unlocked()
    }

    function authenticate(password) {
        lock.secret = password;
        lock.stage = "busy";
        pam.start();
    }

    // =========================
    // Commands
    // =========================
    function profileName(id) {
        const found = lock.profiles.find(p => p.id === id);

        return found ? found.name : id;
    }

    function run(text) {
        const words = text.trim().split(/\s+/).filter(w => w);
        const name = words[0] || "";
        const rest = words.slice(1).join(" ");

        if (lock.confirm && name !== lock.confirm)
            lock.confirm = "";
        switch (name) {
        case "":
            break;
        case "help":
            lock.say("login                 type your password to unlock\n"
                + "switch <profile>      change the style (Tab completes)\n"
                + "profiles              the styles you can switch to\n"
                + "whoami                you and the active profile\n"
                + "fastfetch · date · uptime · music · history · clear\n"
                + "suspend · reboot · poweroff\n"
                + "and a few more: sudo, cowsay, fortune, sl, matrix, hack, 39, exit...", lock.c.subtle);
            break;
        case "login":
            lock.login = lock.user;
            lock.stage = "password";
            break;
        case "switch":
            if (!rest) {
                lock.say("switch <profile>: " + lock.profiles.map(p => p.id).join("  "), lock.c.subtle);
            } else if (lock.profiles.some(p => p.id === rest)) {
                Quickshell.execDetached([lock.wdStyle, "set", rest]);
                lock.profile = rest;
                lock.say(`profile \u2192 ${lock.profileName(rest)}  (the lock stays until you log in)`, lock.c.good);
            } else {
                lock.say(`switch: no profile '${rest}' (profiles lists them)`, lock.c.bad);
            }
            break;
        case "profiles":
        case "ls":
            for (const p of lock.profiles)
                lock.say(`${p.id === lock.profile ? "\u25cf" : " "} ${p.id.padEnd(14)} ${p.name}`, p.id === lock.profile ? lock.c.accent : lock.c.text);
            break;
        case "whoami":
            lock.say(`${lock.user}  \u00b7  profile: ${lock.profileName(lock.profile)}  \u00b7  locked since ${lock.since}`);
            break;
        case "fastfetch":
        case "neofetch":
            for (const [key, value] of lock.facts())
                lock.say(`${key.padEnd(9)} ${value}`, lock.c.text);
            break;
        case "date":
            lock.say(new Date().toString());
            break;
        case "uptime":
            lock.say(`up ${lock.facts().find(f => f[0] === "uptime")?.[1] || "?"}`);
            break;
        case "music":
        case "np":
            lock.say(lock.playing ? `\u266a ${lock.playing}` : "nothing playing", lock.playing ? lock.c.good : lock.c.subtle);
            break;
        case "clear":
            lock.lines = [];
            break;
        case "history":
            lock.history.forEach((h, i) => lock.say(`${String(i + 1).padStart(4)}  ${h}`, lock.c.subtle));
            break;
        case "echo":
            lock.say(rest);
            break;
        case "cowsay":
            lock.cowsay(rest || "moo");
            break;
        case "fortune":
            lock.say(lock.fortunes[Math.floor(Math.random() * lock.fortunes.length)], lock.c.warn);
            break;
        case "sl":
            lock.train = 0;
            break;
        case "matrix":
            lock.rain = !lock.rain;
            break;
        case "hack":
            lock.stage = "busy";
            hacking.step = 0;
            hacking.start();
            break;
        case "sudo":
            lock.say(`${lock.user} is not in the sudoers file. This incident will be reported.`, lock.c.bad);
            break;
        case "rm":
            lock.say(rest.includes("-rf") ? "nice try." : "rm: the files are behind the lock", lock.c.bad);
            break;
        case "exit":
        case "logout":
        case "quit":
            lock.say("there is no exit. type login.", lock.c.warn);
            break;
        case "39":
            lock.say("san-kyu! \u266a (/\u25d5\u30ee\u25d5)/", "#39c5bb");
            break;
        case "lock":
            lock.say("already locked :)", lock.c.subtle);
            break;
        case "suspend":
            Quickshell.execDetached(["systemctl", "suspend"]);
            break;
        case "reboot":
        case "poweroff":
            if (lock.confirm === name) {
                Quickshell.execDetached(["systemctl", name]);
            } else {
                lock.confirm = name;
                lock.say(`${name}: type it again to confirm`, lock.c.warn);
            }
            break;
        default:
            lock.say(`${name}: command not found (help)`, lock.c.bad);
        }
    }

    function cowsay(text) {
        const bar = "-".repeat(text.length + 2);

        lock.say(` ${"_".repeat(text.length + 2)}\n< ${text} >\n ${bar}\n        \\   ^__^\n         \\  (oo)\\_______\n`
            + "            (__)\\       )\\/\\\n                ||----w |\n                ||     ||", lock.c.text);
    }

    function complete(text) {
        const words = text.split(" ");
        const pool = words.length > 1 && words[0] === "switch" ? lock.profiles.map(p => p.id) : lock.commands;
        const last = words[words.length - 1];
        const found = pool.filter(w => w.startsWith(last));

        if (found.length === 1) {
            words[words.length - 1] = found[0];
            return words.join(" ") + (words.length === 1 && found[0] === "switch" ? " " : "");
        }
        if (found.length > 1)
            lock.say(found.join("  "), lock.c.subtle);
        return text;
    }

    // a line typed (Enter): a command, the login name or the password
    function submit(text) {
        if (lock.stage === "password") {
            lock.say(lock.prompt(), lock.c.muted);
            lock.authenticate(text);
        } else if (lock.stage === "login") {
            lock.say(lock.prompt() + text, lock.c.text);
            if (text.trim()) {
                lock.login = text.trim();
                lock.stage = "password";
            }
        } else if (lock.stage === "command") {
            lock.say("> " + text, lock.c.accent);
            if (text.trim())
                lock.history = lock.history.concat([text.trim()]);
            lock.back = -1;
            lock.run(text);
        }
    }

    property string since: ""

    Timer {
        id: hacking

        property int step: 0
        readonly property var steps: ["[\u25a0\u25a1\u25a1\u25a1\u25a1] bypassing the firewall...", "[\u25a0\u25a0\u25a1\u25a1\u25a1] decrypting /etc/shadow...",
            "[\u25a0\u25a0\u25a0\u25a1\u25a1] downloading more RAM...", "[\u25a0\u25a0\u25a0\u25a0\u25a1] reversing the polarity...",
            "[\u25a0\u25a0\u25a0\u25a0\u25a0] ACCESS DENIED. just type login :)"]

        interval: 420
        repeat: true
        onTriggered: {
            lock.say(steps[step], step === steps.length - 1 ? lock.c.bad : lock.c.good);
            if (++step >= steps.length) {
                stop();
                lock.stage = "command";
            }
        }
    }

    // =========================
    // System info (fastfetch), profiles, music
    // =========================
    function facts() {
        const i = lock.info;
        const gb = bytes => (bytes / 1073741824).toFixed(1) + " GiB";
        const list = [];
        const up = i.Uptime ? Math.floor(i.Uptime.uptime / 1000) : 0;

        if (i.OS)
            list.push(["os", i.OS.prettyName]);
        if (i.Host)
            list.push(["host", i.Host.name]);
        if (i.Kernel)
            list.push(["kernel", i.Kernel.release]);
        if (up)
            list.push(["uptime", `${Math.floor(up / 86400)}d ${Math.floor(up % 86400 / 3600)}h ${Math.floor(up % 3600 / 60)}m`]);
        if (i.Packages)
            list.push(["packages", String(i.Packages.all)]);
        list.push(["wm", "Hyprland"]);
        if (i.CPU)
            list.push(["cpu", i.CPU.cpu]);
        if (i.GPU && i.GPU.length)
            list.push(["gpu", i.GPU.map(g => g.name).filter(n => n).join(" + ")]);
        if (i.Memory)
            list.push(["memory", `${gb(i.Memory.used)} / ${gb(i.Memory.total)}`]);
        if (i.Disk && i.Disk.length)
            list.push(["disk", `${gb(i.Disk[0].bytes.used)} / ${gb(i.Disk[0].bytes.total)}`]);
        if (i.Battery && i.Battery.length)
            list.push(["battery", `${Math.round(i.Battery[0].capacity)}%`]);
        list.push(["profile", lock.profileName(lock.profile)]);
        return list;
    }

    Process {
        id: fastfetch

        command: ["fastfetch", "--format", "json", "--structure", "OS:Host:Kernel:Uptime:Packages:CPU:GPU:Memory:Disk:Battery"]
        stdout: StdioCollector {
            onStreamFinished: {
                const data = {};

                try {
                    for (const item of JSON.parse(text))
                        data[item.type] = item.result;
                } catch (e) {}
                data.host = Quickshell.env("HOSTNAME") || "";
                lock.info = Object.assign({}, lock.info, data);
            }
        }
    }

    Process {
        id: hostname

        command: ["hostname", "-s"]
        stdout: StdioCollector {
            onStreamFinished: lock.info = Object.assign({}, lock.info, { host: text.trim() })
        }
    }

    Process {
        id: styles

        command: ["bash", "-c", `for s in $("${lock.wdStyle}" list); do printf '%s\\t%s\\n' "$s" "$(sed -n 's/^NAME="\\(.*\\)"$/\\1/p' "$HOME/.config/wayland-desktop/styles/$s/style.env")"; done; echo "=$("${lock.wdStyle}" current)"`]
        stdout: StdioCollector {
            onStreamFinished: {
                const rows = text.trim().split("\n");

                lock.profiles = rows.filter(r => !r.startsWith("=")).map(r => ({ id: r.split("\t")[0], name: r.split("\t")[1] || r }));
                lock.profile = (rows.find(r => r.startsWith("=")) || "=").slice(1);
            }
        }
    }

    // the image of the user's fastfetch (logo source), else ~/.face
    Process {
        id: logo

        command: ["bash", "-c", "f=$(sed -n 's/.*\"source\": *\"\\(.*\\.\\(png\\|jpg\\|jpeg\\|webp\\)\\)\".*/\\1/p' ~/.config/fastfetch/config.jsonc 2>/dev/null | head -n 1); f=${f/#\\~/$HOME}; [ -f \"$f\" ] && echo \"$f\" || { [ -f ~/.face ] && echo ~/.face; }"]
        stdout: StdioCollector {
            onStreamFinished: picture.source = text.trim() ? "file://" + text.trim() : ""
        }
    }

    Process {
        id: music

        command: ["playerctl", "metadata", "--format", "{{ title }}  \u00b7  {{ artist }}"]
        stdout: StdioCollector {
            onStreamFinished: lock.playing = text.trim()
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: music.running = true
    }

    Component.onCompleted: {
        lock.since = new Date().toTimeString().slice(0, 5);
        fastfetch.running = true;
        hostname.running = true;
        styles.running = true;
        logo.running = true;
        if (lock.shell)
            lock.say("locked. type help, or login to come back.", lock.c.subtle);
    }

    // =========================
    // Look
    // =========================
    Rectangle {
        anchors.fill: parent
        color: lock.c.base
    }

    Image {
        anchors.fill: parent
        source: "file://" + lock.home + "/.config/wayland-desktop/styles/" + (lock.shell ? "tty" : "dev") + "/wallpaper.jpg"
        fillMode: Image.PreserveAspectCrop
        sourceSize.width: 1280
        asynchronous: true
        visible: session.status !== Image.Ready
        opacity: lock.shell ? 0.18 : 0.35
    }

    // Terminal: the session itself behind the lock (its windows, darker under the text)
    Image {
        id: session

        anchors.fill: parent
        source: lock.shell && lock.screenName ? "file://" + Quickshell.env("XDG_RUNTIME_DIR") + "/wd-lock-" + lock.screenName + ".png" : ""
        fillMode: Image.PreserveAspectCrop
        cache: false
        asynchronous: true
        opacity: 0.3
    }

    // CRT scanlines
    Canvas {
        anchors.fill: parent
        opacity: 0.5
        onPaint: {
            const g = getContext("2d");

            g.fillStyle = "rgba(0, 0, 0, 0.35)";
            for (let y = 0; y < height; y += 3)
                g.fillRect(0, y, width, 1);
        }
    }

    // matrix: glyphs falling behind the text
    Repeater {
        model: lock.rain ? 48 : 0

        Text {
            required property int index

            x: (index * 37) % lock.width
            text: "01ｱｲｳｴｵ#$%&*+=<>"[index % 16]
            color: lock.c.good
            opacity: 0.5
            font.family: "JetBrains Mono"
            font.pixelSize: 18

            NumberAnimation on y {
                from: -40
                to: lock.height
                duration: 1800 + (index * 97) % 2200
                loops: Animation.Infinite
            }
        }
    }

    readonly property int fontSize: Math.max(14, Math.round(lock.height / 62))
    readonly property real column: lock.width * 0.07

    // shell: the fastfetch block
    Row {
        id: fetch

        visible: lock.shell
        x: lock.column
        y: lock.height * 0.08
        spacing: lock.fontSize * 2

        Rectangle {
            width: lock.height * 0.3
            height: width
            radius: 12
            color: lock.c.surface
            clip: true

            Image {
                id: picture

                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                sourceSize.width: 512
                asynchronous: true
            }

            Text {
                anchors.centerIn: parent
                visible: picture.status !== Image.Ready
                text: "\u276f_"
                color: lock.c.accent
                font.family: "JetBrains Mono"
                font.pixelSize: lock.fontSize * 4
            }
        }

        Column {
            spacing: 2

            Text {
                text: `${lock.user}@${lock.info.host || "linux"}`
                color: lock.c.good
                font.family: "JetBrains Mono"
                font.pixelSize: lock.fontSize * 1.2
                font.bold: true
            }

            Text {
                text: "\u2500".repeat(28)
                color: lock.c.muted
                font.family: "JetBrains Mono"
                font.pixelSize: lock.fontSize
            }

            Repeater {
                model: lock.facts()

                Row {
                    required property var modelData

                    Text {
                        width: lock.fontSize * 6
                        text: modelData[0]
                        color: lock.c.key
                        font.family: "JetBrains Mono"
                        font.pixelSize: lock.fontSize
                    }

                    Text {
                        text: modelData[1]
                        color: lock.c.text
                        font.family: "JetBrains Mono"
                        font.pixelSize: lock.fontSize
                    }
                }
            }

            Row {
                topPadding: lock.fontSize * 0.6
                spacing: 6

                Repeater {
                    model: ["#eb6f92", "#f6c177", "#ebbcba", "#31748f", "#9ccfd8", "#c4a7e7", "#e0def4", "#6e6a86"]

                    Rectangle {
                        required property string modelData

                        width: lock.fontSize * 2
                        height: lock.fontSize
                        radius: 3
                        color: modelData
                    }
                }
            }
        }
    }

    // getty: the info of the Dev lock (time, then the console)
    Column {
        visible: !lock.shell
        x: lock.column
        y: lock.height * 0.12
        spacing: 6

        Text {
            id: clock

            text: new Date().toTimeString().slice(0, 5)
            color: lock.c.text
            font.family: "JetBrains Mono"
            font.pixelSize: lock.fontSize * 5

            Timer {
                interval: 1000
                running: true
                repeat: true
                onTriggered: clock.text = new Date().toTimeString().slice(0, 5)
            }
        }

        Text {
            text: `${lock.info.OS ? lock.info.OS.prettyName : "Linux"}  \u00b7  kernel ${lock.info.Kernel ? lock.info.Kernel.release : ""} on an x86_64 (tty1)`
            color: lock.c.muted
            font.family: "JetBrains Mono"
            font.pixelSize: lock.fontSize
        }
    }

    // the transcript and the prompt: the prompt stays at the bottom (never cut), the old lines go out at the top, long
    // lines wrap
    Item {
        id: board

        x: lock.column
        y: lock.shell ? fetch.y + fetch.height + lock.fontSize * 2 : lock.height * 0.36
        width: lock.width - 2 * lock.column
        height: lock.height - y - lock.fontSize * 3.6
        clip: true

        Column {
            id: transcript

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: promptLine.top

            Repeater {
                model: lock.lines.slice(-80)

                Text {
                    required property var modelData

                    width: transcript.width
                    text: modelData.text
                    color: modelData.color
                    font.family: "JetBrains Mono"
                    font.pixelSize: lock.fontSize
                    textFormat: Text.PlainText
                    wrapMode: Text.WrapAnywhere
                }
            }
        }

        Row {
            id: promptLine

            anchors.left: parent.left
            anchors.bottom: parent.bottom

            Text {
                text: lock.prompt()
                color: lock.stage === "command" ? lock.c.accent : lock.c.text
                font.family: "JetBrains Mono"
                font.pixelSize: lock.fontSize
            }

            Text {
                // the password is never shown, not even as dots (like a console)
                text: lock.stage === "password" ? "" : input.text
                color: lock.c.text
                font.family: "JetBrains Mono"
                font.pixelSize: lock.fontSize
                textFormat: Text.PlainText
                elide: Text.ElideLeft
                width: Math.min(implicitWidth, board.width - x - lock.fontSize * 2)
            }

            Rectangle {
                width: lock.fontSize * 0.6
                height: lock.fontSize * 1.2
                visible: lock.stage !== "busy"
                color: lock.c.text

                SequentialAnimation on opacity {
                    loops: Animation.Infinite

                    NumberAnimation {
                        to: 0
                        duration: 530
                    }

                    NumberAnimation {
                        to: 1
                        duration: 530
                    }
                }
            }
        }
    }

    // status line, like tmux
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 10
        height: lock.fontSize * 1.9
        radius: 8
        color: lock.c.surface

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            text: `[locked] ${lock.user}@${lock.info.host || "linux"}   ${lock.playing ? "\u266a " + lock.playing : ""}`
            color: lock.c.subtle
            font.family: "JetBrains Mono"
            font.pixelSize: lock.fontSize * 0.9
        }

        Text {
            id: status

            anchors.right: parent.right
            anchors.rightMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            text: Qt.formatDateTime(new Date(), "ddd dd MMM  HH:mm")
            color: lock.c.warn
            font.family: "JetBrains Mono"
            font.pixelSize: lock.fontSize * 0.9

            Timer {
                interval: 10000
                running: true
                repeat: true
                onTriggered: status.text = Qt.formatDateTime(new Date(), "ddd dd MMM  HH:mm")
            }
        }
    }

    // sl: a train crosses the screen
    Text {
        visible: lock.train >= 0
        x: lock.width - lock.train * (lock.width + width)
        y: lock.height * 0.45
        text: "      ====        ________                ___________\n  _D _|  |_______/        \\__I_I_____===__|_________|\n   |(_)---  |   H\\________/ |   |        =|___ ___|\n   /     |  |   H  |  |     |   |         ||_| |_||\n  |      |  |   H  |__--------------------| [___] |\n  | ________|___H__/__|_____/[][]~\\_______|       |\n  |/ |   |-----------I_____I [][] []  D   |=======|_\n__/ =| o |=-~~\\  /~~\\  /~~\\  /~~\\ ____Y___________|__\n |/-=|___|=    ||    ||    ||    |_____/~\\___/\n  \\_/      \\O=====O=====O=====O_/      \\_/"
        color: lock.c.text
        font.family: "JetBrains Mono"
        font.pixelSize: lock.fontSize
    }

    NumberAnimation {
        target: lock
        property: "train"
        running: lock.train === 0
        from: 0
        to: 1
        duration: 3500
        onFinished: lock.train = -1
    }

    // the keys (hidden field: the transcript shows what is typed)
    TextInput {
        id: input

        width: 0
        height: 0
        opacity: 0
        focus: true
        echoMode: lock.stage === "password" ? TextInput.Password : TextInput.Normal
        Keys.onPressed: event => {
            if (lock.stage === "busy") {
                event.accepted = true;
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                const text = input.text;

                input.text = "";
                lock.submit(text);
                event.accepted = true;
            } else if (event.key === Qt.Key_Tab && lock.stage === "command") {
                input.text = lock.complete(input.text);
                input.cursorPosition = input.text.length;
                event.accepted = true;
            } else if ((event.key === Qt.Key_Up || event.key === Qt.Key_Down) && lock.stage === "command" && lock.history.length) {
                lock.back = event.key === Qt.Key_Up ? Math.min(lock.history.length - 1, lock.back + 1) : Math.max(-1, lock.back - 1);
                input.text = lock.back < 0 ? "" : lock.history[lock.history.length - 1 - lock.back];
                event.accepted = true;
            } else if (event.modifiers & Qt.ControlModifier && event.key === Qt.Key_L) {
                lock.lines = [];
                event.accepted = true;
            } else if (event.modifiers & Qt.ControlModifier && event.key === Qt.Key_C) {
                lock.say(lock.prompt() + (lock.stage === "password" ? "" : input.text) + "^C", lock.c.muted);
                input.text = "";
                lock.stage = lock.shell ? "command" : "login";
                event.accepted = true;
            }
        }
    }
}
