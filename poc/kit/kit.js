// Desktop POC kit: window manager, scenes, lock screen, notifications, context menu, launcher and the shared apps
// (files, browser, terminal, music, settings, viewer), skinned by each style page through CSS variables

"use strict";

const Kit = (() => {
    // ===== Helpers =====

    const ESCAPES = {"&": "&amp;", "<": "&lt;", ">": "&gt;", "\"": "&quot;"};
    const $ = (selector, root = document) => root.querySelector(selector);
    const $$ = (selector, root = document) => [...root.querySelectorAll(selector)];
    const pad = (value) => String(value).padStart(2, "0");
    const esc = (text) => String(text).replace(/[&<>"]/g, (char) => ESCAPES[char]);
    const capitalize = (text) => text[0].toUpperCase() + text.slice(1);

    function element(markup)
    {
        const template = document.createElement("template");

        template.innerHTML = markup.trim();
        return template.content.firstElementChild;
    }

    // ===== Events =====

    const listeners = {};

    function on(name, callback)
    {
        (listeners[name] ??= []).push(callback);
    }

    function emit(name, data)
    {
        for (const callback of listeners[name] ?? [])
            callback(data);
    }

    // ===== Config =====

    const ICONS = {
        dir: "📁", text: "📄", code: "📜", image: "🖼️", audio: "🎵", doc: "📕", archive: "📦",
        files: "📁", browser: "🌐", terminal: "⌨️", music: "🎧", settings: "⚙️", viewer: "🖼️", lock: "🔒",
    };
    const APP_NAMES = ["files", "browser", "terminal", "music", "settings"];
    const SCENES = [
        ["desktop", "Desktop"], ["lock", "Lock"], ["files", "Files"], ["browser", "Browser"],
        ["terminal", "Terminal"], ["music", "Music"], ["settings", "Settings"],
    ];
    const DEFAULT_TRACKS = [
        {
            title: "Midnight Compiler", artist: "Lo-fi Kernel", bpm: 84, wave: "triangle", gain: 0.2,
            scale: [57, 60, 62, 64, 67, 69, 72, 74, 76, 79, 81, 84, 86, 88, 91, 93],
            lead: "4--.6-5.4---2-..3--.4-3.2---0-..4--.6-5.7---6-..5--.4-3.2-------",
            bass: "0-------3-------5-------4-------",
            drums: "k...s..hk.k.s..h",
        },
        {
            title: "Ring Zero", artist: "Lo-fi Kernel", bpm: 92, wave: "square", gain: 0.08,
            scale: [55, 58, 60, 62, 65, 67, 70, 72, 74, 77, 79, 82, 84, 86, 89, 91],
            lead: "7.7.9.7.5---4.5.7.7.9.a.9---7...5.5.7.5.4---2.4.5.4.2.0.2-------",
            bass: "0---0---3---3---5---5---4---4---",
            drums: "k.h.s.h.k.k.s.h.",
        },
    ];

    let config = null;
    let desk = null;
    const state = {scene: "", dnd: false};
    const home = () => `/home/${config.user}`;
    const icon = (name) => config.icons[name] ?? ICONS[name] ?? "•";

    // ===== Clocks =====

    const CLOCKS = {
        hm: (now) => `${pad(now.getHours())}:${pad(now.getMinutes())}`,
        hms: (now) => `${pad(now.getHours())}:${pad(now.getMinutes())}:${pad(now.getSeconds())}`,
        date: (now) => now.toLocaleDateString("en-GB", {weekday: "short", day: "numeric", month: "short"}),
        long: (now) => now.toLocaleDateString("en-GB", {weekday: "long", day: "numeric", month: "long", year: "numeric"}),
        hex: (now) => "0x" + (now.getHours() * 3600 + now.getMinutes() * 60 + now.getSeconds()).toString(16).padStart(5, "0"),
    };

    function update_clocks()
    {
        const now = new Date();

        for (const clock of $$("[data-clock]"))
            clock.textContent = (CLOCKS[clock.dataset.clock] ?? CLOCKS.hm)(now);
    }

    // ===== Windows =====

    const windows = new Map();
    const APPS = {};
    let top_z = 10;
    let open_order = 0;
    let cascade = 0;
    let spawned = 1;

    function area()
    {
        const style = getComputedStyle(desk);
        const read = (name) => parseFloat(style.getPropertyValue(name)) || 0;
        const top = read("--area-top");
        const left = read("--area-left");

        return {
            top, left, width: desk.clientWidth - left - read("--area-right"), height: desk.clientHeight - top - read("--area-bottom"),
            gap_in: read("--k-gap-in"), gap_out: read("--k-gap-out"),
        };
    }

    function title_bar(title, icon_text)
    {
        const chrome = config.chrome;

        return element(`<header class="win-bar"><span class="win-icon">${icon_text ?? ""}</span><span class="win-title">${esc(title)}</span>`
            + `<span class="win-ctl"><button data-act="min" title="Minimize">${chrome.min}</button>`
            + `<button data-act="max" title="Maximize">${chrome.max}</button>`
            + `<button data-act="close" title="Close">${chrome.close}</button></span></header>`);
    }

    function register(win)
    {
        if (config.layout === "float")
            win.append(element("<span class=\"win-grip\"></span>"));
        win.dataset.state = "closed";
        win.classList.add("is-hidden");
        windows.set(win.id, win);
    }

    // windows written in the page: their content becomes the body, the title bar is generated
    function adopt(win)
    {
        const body = document.createElement("div");

        body.className = "win-body";
        body.append(...win.childNodes);
        win.append(title_bar(win.dataset.title ?? win.id, win.dataset.icon), body);
        register(win);
    }

    function create_window(id, {title, icon: icon_text, body, size = [680, 440], cls = ""})
    {
        const win = element(`<section class="win app app-${cls}" id="${id}" data-title="${esc(title)}"></section>`);
        const content = element("<div class=\"win-body\"></div>");
        const box = area();
        const width = Math.min(size[0], box.width - 40);
        const height = Math.min(size[1], box.height - 40);

        content.innerHTML = body;
        win.append(title_bar(title, icon_text), content);
        cascade = (cascade + 1) % 5;
        Object.assign(win.style, {
            width: `${width}px`,
            height: `${height}px`,
            left: `${box.left + (box.width - width) / 2 + (cascade - 2) * 28}px`,
            top: `${box.top + Math.max(10, (box.height - height) / 2 + (cascade - 2) * 22)}px`,
        }, config.positions[id] ?? {});
        desk.append(win);
        register(win);
        return win;
    }

    function get_window(id)
    {
        const name = id.replace(/-\d+$/, "");

        if (!windows.has(id) && APPS[name])
            APPS[name](id);
        return windows.get(id);
    }

    function set_state(win, value)
    {
        const was_open = win.dataset.state === "open";
        const animate = was_open && value !== "open" && !document.body.classList.contains("no-motion");

        win.dataset.state = value;
        win.classList.remove("is-closing", "is-minimizing");
        if (value === "open") {
            win.classList.remove("is-hidden");
        } else if (animate) {
            win.classList.add(value === "min" ? "is-minimizing" : "is-closing");
            setTimeout(() => {
                win.classList.remove("is-closing", "is-minimizing");
                if (win.dataset.state !== "open")
                    win.classList.add("is-hidden");
            }, 200);
        } else {
            win.classList.add("is-hidden");
        }
        if (value !== "open")
            win.classList.remove("is-active");
        relayout();
        render_tasks();
        emit("window", {id: win.id, state: value});
    }

    function focus(win)
    {
        for (const other of $$(".win.is-active", desk))
            other.classList.remove("is-active");
        win.classList.add("is-active");
        win.style.zIndex = ++top_z;
        render_tasks();
    }

    function open(id)
    {
        const win = get_window(id);

        if (!win)
            return null;
        if (win.dataset.state !== "open") {
            win.dataset.order = ++open_order;
            set_state(win, "open");
        }
        focus(win);
        $(".t-input", win)?.focus();
        return win;
    }

    function toggle(id)
    {
        const win = get_window(id);

        if (win?.dataset.state === "open" && win.classList.contains("is-active"))
            set_state(win, "min");
        else
            open(id);
    }

    function close(id)
    {
        const win = windows.get(id);

        if (win)
            set_state(win, "closed");
    }

    function set_layout(mode)
    {
        config.layout = mode;
        document.body.classList.toggle("k-tile", mode === "tile");
        for (const win of windows.values()) {
            win.classList.remove("is-max");
            win.style.visibility = "";
        }
        relayout();
        emit("layout", mode);
    }

    function maximize(id)
    {
        windows.get(id)?.classList.toggle("is-max");
        relayout();
    }

    function active()
    {
        return $(".win.is-active", desk)?.id ?? null;
    }

    function spawn(name)
    {
        return open(`${name}-${++spawned}`);
    }

    function place_large(win)
    {
        const box = area();
        const width = Math.min(box.width - 40, Math.max(760, box.width * 0.64));
        const height = Math.min(box.height - 40, Math.max(480, box.height * 0.74));

        win.classList.remove("is-max");
        Object.assign(win.style, {
            width: `${width}px`,
            height: `${height}px`,
            left: `${box.left + (box.width - width) / 2}px`,
            top: `${box.top + (box.height - height) / 2}px`,
        });
    }

    // tiling (tmux-like): first window on the left, the others stacked on the right, a maximized one zooms
    function relayout()
    {
        if (config.layout !== "tile")
            return;
        const list = [...windows.values()].filter((win) => win.dataset.state === "open").sort((a, b) => a.dataset.order - b.dataset.order);
        const zoomed = list.find((win) => win.classList.contains("is-max"));
        const box = area();
        const place = (win, left, top, width, height) => Object.assign(win.style, {
            left: `${left}px`, top: `${top}px`, width: `${width}px`, height: `${height}px`,
        });

        for (const win of list)
            win.style.visibility = !zoomed || win === zoomed ? "" : "hidden";
        if (zoomed || list.length === 1)
            return place(zoomed ?? list[0], box.left + box.gap_out, box.top + box.gap_out, box.width - box.gap_out * 2, box.height - box.gap_out * 2);
        if (!list.length)
            return;
        const master = Math.round(box.width * 0.56);
        const rest = list.slice(1);
        const height = (box.height - box.gap_out * 2 - box.gap_in * (rest.length - 1)) / rest.length;
        const right = box.left + master + box.gap_in / 2;

        place(list[0], box.left + box.gap_out, box.top + box.gap_out, master - box.gap_out - box.gap_in / 2, box.height - box.gap_out * 2);
        rest.forEach((win, index) => place(win, right, box.top + box.gap_out + index * (height + box.gap_in), box.width - master - box.gap_in / 2 - box.gap_out, height));
    }

    function drag(event, win, handle, resize)
    {
        const start = {x: event.clientX, y: event.clientY, left: win.offsetLeft, top: win.offsetTop, width: win.offsetWidth, height: win.offsetHeight};
        const move = (move_event) => {
            const dx = move_event.clientX - start.x;
            const dy = move_event.clientY - start.y;

            if (resize) {
                win.style.width = `${Math.max(280, start.width + dx)}px`;
                win.style.height = `${Math.max(160, start.height + dy)}px`;
            } else {
                win.style.left = `${start.left + dx}px`;
                win.style.top = `${Math.max(0, start.top + dy)}px`;
            }
        };
        const stop = () => {
            win.classList.remove("is-dragging");
            handle.removeEventListener("pointermove", move);
            handle.removeEventListener("pointerup", stop);
            handle.removeEventListener("pointercancel", stop);
        };

        Object.assign(win.style, {left: `${start.left}px`, top: `${start.top}px`, right: "auto", bottom: "auto"});
        win.classList.add("is-dragging");
        handle.setPointerCapture(event.pointerId);
        handle.addEventListener("pointermove", move);
        handle.addEventListener("pointerup", stop);
        handle.addEventListener("pointercancel", stop);
    }

    function render_tasks()
    {
        const list = [...windows.values()].filter((win) => win.dataset.state !== "closed").sort((a, b) => a.dataset.order - b.dataset.order);

        for (const bar of $$("[data-kit=\"tasks\"]")) {
            bar.innerHTML = list.map((win, index) => {
                const title = $(".win-title", win).textContent;
                const label = config.task_label ? config.task_label(win, index, title) : esc(title);
                const classes = `task${win.classList.contains("is-active") ? " is-active" : ""}${win.dataset.state === "min" ? " is-min" : ""}`;

                return `<button class="${classes}" data-task="${win.id}">${label}</button>`;
            }).join("");
        }
        for (const button of $$("[data-app]")) {
            const win = windows.get(button.dataset.app);

            button.classList.toggle("is-open", Boolean(win) && win.dataset.state !== "closed");
        }
    }

    // ===== Scenes =====

    function scene(name)
    {
        if (name === "lock") {
            show_lock();
        } else {
            const wanted = name === "desktop" ? config.desktop : config.scenes[name] ?? [name];

            hide_lock();
            for (const win of windows.values())
                if (win.dataset.state === "open" && !wanted.includes(win.id))
                    set_state(win, "min");
            wanted.forEach((id, index) => {
                const win = open(id);

                if (win && index === 0 && config.layout === "float" && ["files", "browser", "terminal"].includes(name))
                    place_large(win);
            });
            // the main window of the scene ends on top with the focus (open order, used by tiling, is kept)
            if (wanted.length)
                open(wanted[0]);
        }
        if (name !== "lock" && state.scene && state.scene !== "lock") {
            document.body.classList.remove("k-switch");
            void document.body.offsetWidth;
            document.body.classList.add("k-switch");
            setTimeout(() => document.body.classList.remove("k-switch"), 400);
        }
        state.scene = name;
        // "#scene-x", not "#x": a hash equal to a window id would scroll the page to it
        history.replaceState(null, "", `#scene-${name}`);
        desk.scrollTop = 0;
        document.scrollingElement.scrollTop = 0;
        for (const button of $$("[data-scene]"))
            button.classList.toggle("is-on", button.dataset.scene === name);
        emit("scene", name);
    }

    // ===== Lock screen =====

    let lock_el = null;
    let lock_timer = 0;

    function build_lock()
    {
        const lock = config.lock;
        const inner = lock.html ?? `<div class="lock-clock" data-clock="hm"></div><div class="lock-date" data-clock="long"></div>`
            + `<div class="lock-card"><div class="lock-avatar">${lock.avatar ?? esc(config.user[0].toUpperCase())}</div>`
            + `<div class="lock-user">${esc(config.user)}</div>`
            + `<input class="lock-input" type="password" placeholder="${esc(lock.placeholder ?? "Password")}" autocomplete="off">`
            + `<div class="lock-hint">${lock.hint ?? "Any password unlocks"}</div></div>`;
        const input = () => $(".lock-input", lock_el);

        lock_el = element(`<div class="lock is-hidden">${lock.decor ?? ""}<div class="lock-inner">${inner}</div></div>`);
        document.body.append(lock_el);
        lock_el.addEventListener("pointerdown", () => {
            lock_el.classList.add("is-awake");
            setTimeout(() => input().focus());
        });
        input().addEventListener("keydown", (event) => {
            if (event.key !== "Enter")
                return;
            if (!input().value) {
                lock_el.classList.remove("is-wrong");
                void lock_el.offsetWidth;
                lock_el.classList.add("is-wrong");
                return;
            }
            scene("desktop");
            notify(lock.welcome ?? "Welcome back", `${config.user}@${config.host}`, icon("lock"));
        });
    }

    function show_lock()
    {
        clearTimeout(lock_timer);
        lock_el.classList.remove("is-hidden", "is-leaving", "is-awake", "is-wrong");
        $(".lock-input", lock_el).value = "";
        setTimeout(() => $(".lock-input", lock_el).focus(), 60);
        emit("lock", true);
    }

    function hide_lock()
    {
        if (lock_el.classList.contains("is-hidden"))
            return;
        lock_el.classList.add("is-leaving");
        lock_timer = setTimeout(() => lock_el.classList.add("is-hidden"), 450);
        emit("lock", false);
    }

    // ===== Notifications =====

    function notify(title, body = "", icon_text = "")
    {
        const box = $(".toasts") ?? document.body.appendChild(element("<div class=\"toasts\"></div>"));
        const toast = element(`<div class="toast"><span class="toast-icon">${icon_text}</span><div><b>${esc(title)}</b><div>${esc(body)}</div></div></div>`);

        if (state.dnd)
            return;
        box.append(toast);
        toast.addEventListener("click", () => toast.remove());
        setTimeout(() => toast.classList.add("is-out"), 4200);
        setTimeout(() => toast.remove(), 4700);
    }

    // ===== Context menu =====

    let menu = null;
    let menu_items = [];

    function show_menu(event)
    {
        const next_wallpaper = () => {
            const index = config.wallpapers.findIndex((wall) => document.body.classList.contains(wall.cls));

            set_wallpaper((index + 1) % config.wallpapers.length);
        };

        menu_items = [
            ...config.context,
            {label: "Open terminal", run: () => open("terminal")},
            {label: "Open files", run: () => open("files")},
            {label: "Open browser", run: () => open("browser")},
            ...(config.wallpapers.length > 1 ? [{label: "Next wallpaper", run: next_wallpaper}] : []),
            {label: "Settings", run: () => open("settings")},
            {label: "Lock screen", run: () => scene("lock")},
        ];
        menu.innerHTML = menu_items.map((item, index) => `<button data-ctx="${index}">${esc(item.label)}</button>`).join("");
        menu.classList.remove("is-hidden");
        menu.style.left = `${Math.min(event.clientX, innerWidth - menu.offsetWidth - 8)}px`;
        menu.style.top = `${Math.min(event.clientY, innerHeight - menu.offsetHeight - 8)}px`;
    }

    function hide_menu()
    {
        menu.classList.add("is-hidden");
    }

    // ===== Launcher =====

    let launcher = null;

    function launcher_entries()
    {
        const widgets = config.desktop.map((id) => windows.get(id)).filter(Boolean)
            .map((win) => ({id: win.id, name: win.dataset.title ?? win.id, icon: win.dataset.icon ?? "◻"}));

        return [
            ...APP_NAMES.map((id) => ({id, name: capitalize(id), icon: icon(id)})),
            ...widgets,
            {id: "lock", name: "Lock screen", icon: icon("lock")},
        ];
    }

    function render_launcher()
    {
        const filter = $(".l-search", launcher).value.toLowerCase();

        $(".l-grid", launcher).innerHTML = launcher_entries().filter((entry) => entry.name.toLowerCase().includes(filter))
            .map((entry) => `<button class="l-item" data-launch="${entry.id}"><span>${entry.icon}</span>${esc(entry.name)}</button>`).join("");
    }

    function toggle_launcher(show = launcher.classList.contains("is-hidden"))
    {
        launcher.classList.toggle("is-hidden", !show);
        if (!show)
            return;
        $(".l-search", launcher).value = "";
        render_launcher();
        setTimeout(() => $(".l-search", launcher).focus());
    }

    function launch(id)
    {
        toggle_launcher(false);
        if (id === "lock")
            scene("lock");
        else
            open(id);
    }

    function build_launcher()
    {
        launcher = element("<div class=\"launcher is-hidden\"><div class=\"l-box\"><input class=\"k-input l-search\" placeholder=\"Search apps\"><div class=\"l-grid\"></div></div></div>");
        document.body.append(launcher);
        $(".l-search", launcher).addEventListener("input", render_launcher);
        $(".l-search", launcher).addEventListener("keydown", (event) => {
            const first = $(".l-item", launcher);

            if (event.key === "Enter" && first)
                launch(first.dataset.launch);
        });
        launcher.addEventListener("click", (event) => {
            const item = event.target.closest(".l-item");

            if (item)
                launch(item.dataset.launch);
            else if (!event.target.closest(".l-box"))
                toggle_launcher(false);
        });
    }

    // ===== File system =====

    const fs = new Map([["/", {type: "dir"}]]);
    const DEFAULT_PICTURES = [
        ["sunset.jpg", "linear-gradient(170deg, #f3b26b, #c96a3d 40%, #4b2a3f 80%)"],
        ["harbor.jpg", "linear-gradient(180deg, #2c4f72, #5d8bb0 50%, #1d2b3a)"],
        ["forest.jpg", "linear-gradient(180deg, #a7b8a0, #4f6b4a 55%, #1e2a1c)"],
        ["neon.jpg", "linear-gradient(160deg, #1a1030, #6b2a6e 55%, #f05a7e)"],
    ];

    function fs_add(path, node)
    {
        const parts = path.split("/").filter(Boolean);

        for (let i = 1; i < parts.length; ++i) {
            const dir = `/${parts.slice(0, i).join("/")}`;

            if (!fs.has(dir))
                fs.set(dir, {type: "dir"});
        }
        if (node.type === "file" && node.content !== undefined && !node.size)
            node.size = `${node.content.length} B`;
        fs.set(path, node);
    }

    function fs_list(path)
    {
        const prefix = path === "/" ? "/" : `${path}/`;
        const entries = [];

        for (const [entry, node] of fs) {
            const name = entry.slice(prefix.length);

            if (entry !== path && entry.startsWith(prefix) && !name.includes("/"))
                entries.push({path: entry, name, ...node});
        }
        return entries.sort((a, b) => (a.type === b.type ? a.name.localeCompare(b.name) : a.type === "dir" ? -1 : 1));
    }

    function fs_resolve(cwd, target = "")
    {
        const path = target.startsWith("~") ? home() + target.slice(1) : target.startsWith("/") ? target : `${cwd}/${target}`;
        const parts = [];

        for (const part of path.split("/")) {
            if (part === "..")
                parts.pop();
            else if (part && part !== ".")
                parts.push(part);
        }
        return `/${parts.join("/")}`;
    }

    function fs_remove(path)
    {
        for (const entry of [...fs.keys()])
            if (entry === path || entry.startsWith(`${path}/`))
                fs.delete(entry);
    }

    const short_path = (path) => (path.startsWith(home()) ? `~${path.slice(home().length)}` : path);
    const image_css = (node) => [node.src ? `url("${node.src}")` : null, node.fallback ?? "linear-gradient(135deg, #555, #222)"].filter(Boolean).join(", ");
    const kind_icon = (node) => icon(node.type === "dir" ? "dir" : node.kind);

    function build_fs()
    {
        const add = (path, kind, extra = {}) => fs_add(fs_resolve(home(), path), {type: kind === "dir" ? "dir" : "file", kind, ...extra});

        add("Documents/notes.md", "text", {content: "# Notes\n\n- try every desktop POC\n- pick a style for the real config\n- GNOME or Hyprland?\n"});
        add("Documents/todo.txt", "text", {content: "[x] tmux modes\n[x] nvim completion\n[x] desktop POCs\n[ ] wayland config\n[ ] dotfiles install script\n"});
        add("Documents/report.pdf", "doc", {size: "142 KB"});
        add("Projects/libutils/README.md", "text", {content: "# libutils\n\nC++20 utility library: arguments, cli, exceptions, algorithms (c2dmp-hsm, s.o.s).\n"});
        add("Projects/libutils/CMakeLists.txt", "code", {content: "cmake_minimum_required(VERSION 3.25)\nproject(utils VERSION 4.0.0 LANGUAGES CXX)\n\nset(CMAKE_CXX_STANDARD 20)\nadd_library(utils STATIC ${SRC})\n"});
        add("Projects/libutils/src/main.cpp", "code", {content: "#include <iostream>\n\nint main(void)\n{\n    std::cout << \"hello\" << std::endl;\n    return 0;\n}\n"});
        add("Projects/dotfiles/tmux.conf", "code", {content: "set -g prefix C-b\nset -g mouse on\nset -g pane-border-lines heavy\nrun-shell ~/.config/tmux/mode.sh\n"});
        add("Projects/dotfiles/init.lua", "code", {content: "require('basics')\nrequire('lazy').setup('plugins')\nrequire('matching.checks').setup()\n"});
        for (const [name, fallback] of DEFAULT_PICTURES)
            add(`Pictures/${name}`, "image", {fallback, size: "2.4 MB"});
        config.tracks.forEach((track, index) => {
            add(`Music/${track.title.toLowerCase().replace(/[^a-z0-9]+/g, "-")}.ogg`, "audio", {track: index, size: "3.9 MB"});
        });
        add("Downloads/fedora-44-x86_64.iso", "archive", {size: "2.1 GB"});
        add("Downloads/wallpaper.png", "image", {fallback: "radial-gradient(circle at 30% 30%, var(--k-accent), #111)", size: "5.1 MB"});
        add("Desktop", "dir");
        add("/etc/hostname", "text", {content: `${config.host}\n`});
        add("/etc/os-release", "text", {content: "NAME=\"Fedora Linux\"\nVERSION=\"44 (Workstation Edition)\"\nID=fedora\n"});
        add("/tmp", "dir");
        for (const [path, node] of Object.entries(config.files))
            fs_add(fs_resolve(home(), path), {type: "file", ...node});
    }

    function open_file(path)
    {
        const node = fs.get(path);

        if (!node)
            return;
        if (node.type === "dir")
            open("files").kit_go(path);
        else if (node.kind === "audio")
            (open("music"), play(node.track));
        else
            view(path);
    }

    // ===== App: viewer =====

    APPS.viewer = (id) => create_window(id, {title: "Viewer", icon: icon("viewer"), size: [660, 480], cls: "viewer", body: "<div class=\"v-body\"></div>"});

    function view(path)
    {
        const node = fs.get(path);
        const win = get_window("viewer");
        const text = esc(node.content ?? `(binary ${node.kind} file, ${node.size ?? "?"})`);

        $(".win-title", win).textContent = path.split("/").pop();
        $(".v-body", win).innerHTML = node.kind === "image"
            ? `<div class="v-image" style="background-image: ${esc(image_css(node))}"></div>`
            : `<pre class="v-text">${text.split("\n").map((line, index) => `<span class="v-ln">${index + 1}</span>${line}`).join("\n")}</pre>`;
        open("viewer");
    }

    // ===== App: files =====

    const PLACES = [["Home", "~"], ["Desktop", "~/Desktop"], ["Documents", "~/Documents"], ["Projects", "~/Projects"],
        ["Pictures", "~/Pictures"], ["Music", "~/Music"], ["Downloads", "~/Downloads"], ["Root", "/"]];

    APPS.files = (id) => {
        const win = create_window(id, {
            title: "Files", icon: icon("files"), size: [820, 500], cls: "files",
            body: "<div class=\"f-tool\"><button class=\"k-btn\" data-f=\"back\" title=\"Back\">‹</button><button class=\"k-btn\" data-f=\"up\" title=\"Parent\">↑</button>"
                + "<div class=\"f-path\"></div><input class=\"k-input f-search\" placeholder=\"Filter\"><button class=\"k-btn\" data-f=\"view\" title=\"Grid / list\">☰</button></div>"
                + "<div class=\"f-main\"><nav class=\"f-side\"></nav><div class=\"f-items\"></div><aside class=\"f-preview\"></aside></div><div class=\"f-status\"></div>",
        });
        const files = {cwd: home(), back: [], selected: null, filter: ""};
        const items = $(".f-items", win);

        function preview()
        {
            const box = $(".f-preview", win);
            const node = fs.get(files.selected);
            let body = "";

            if (!node) {
                box.innerHTML = `<div class="f-pname">${icon("dir")} ${esc(short_path(files.cwd))}</div><div class="k-muted">${fs_list(files.cwd).length} items</div>`;
                return;
            }
            if (node.type === "dir")
                body = `<p class="k-muted">${fs_list(files.selected).length} items</p>`;
            else if (node.kind === "image")
                body = `<div class="f-big" style="background-image: ${esc(image_css(node))}"></div>`;
            else if (node.kind === "audio")
                body = `<p>${esc(config.tracks[node.track]?.artist ?? "")}</p><button class="k-btn k-primary" data-f="open">▶ Play</button>`;
            else
                body = `<pre>${esc(node.content ?? "(binary file)")}</pre>`;
            box.innerHTML = `<div class="f-pname">${kind_icon(node)} ${esc(files.selected.split("/").pop())}</div>`
                + `<div class="k-muted">${node.type === "dir" ? "folder" : node.kind} · ${esc(node.size ?? "4.0K")}</div>${body}`
                + (node.type === "dir" || node.kind === "audio" ? "" : "<button class=\"k-btn\" data-f=\"open\">Open</button>");
        }

        function render()
        {
            const list = fs_list(files.cwd).filter((entry) => entry.name.toLowerCase().includes(files.filter));
            const parts = files.cwd.split("/").filter(Boolean);

            $(".f-path", win).innerHTML = "<button data-go=\"/\">/</button>" + parts.map((part, index) => {
                return `<button data-go="/${esc(parts.slice(0, index + 1).join("/"))}">${esc(part)}</button>`;
            }).join("<span>›</span>");
            items.innerHTML = list.map((entry) => {
                const thumb = entry.kind === "image" ? ` is-thumb" style="background-image: ${esc(image_css(entry))}` : "";

                return `<button class="f-item${entry.path === files.selected ? " is-sel" : ""}" data-path="${esc(entry.path)}">`
                    + `<span class="f-ico${thumb}">${entry.kind === "image" ? "" : kind_icon(entry)}</span><span class="f-name">${esc(entry.name)}</span></button>`;
            }).join("") || "<div class=\"k-muted f-empty\">Empty folder</div>";
            for (const button of $$(".f-side button", win))
                button.classList.toggle("is-on", button.dataset.go === files.cwd);
            $(".f-status", win).textContent = `${list.length} items · ${short_path(files.cwd)} · double-click to open`;
            $(".win-title", win).textContent = `Files — ${short_path(files.cwd)}`;
            preview();
        }

        function go(path)
        {
            if (path !== files.cwd)
                files.back.push(files.cwd);
            files.cwd = path;
            files.selected = null;
            files.filter = "";
            $(".f-search", win).value = "";
            render();
        }

        $(".f-side", win).innerHTML = PLACES.map(([label, path]) => `<button data-go="${esc(fs_resolve("/", path))}">${label}</button>`).join("");
        win.addEventListener("click", (event) => {
            const target = event.target.closest("[data-go], [data-f], .f-item");

            if (!target)
                return;
            if (target.dataset.go) {
                go(target.dataset.go);
            } else if (target.classList.contains("f-item")) {
                $$(".f-item.is-sel", win).forEach((item) => item.classList.remove("is-sel"));
                target.classList.add("is-sel");
                files.selected = target.dataset.path;
                preview();
            } else if (target.dataset.f === "back" && files.back.length) {
                files.cwd = files.back.pop();
                files.selected = null;
                render();
            } else if (target.dataset.f === "up") {
                go(fs_resolve(files.cwd, ".."));
            } else if (target.dataset.f === "view") {
                items.classList.toggle("is-list");
            } else if (target.dataset.f === "open") {
                open_file(files.selected);
            }
        });
        win.addEventListener("dblclick", (event) => {
            const item = event.target.closest(".f-item");

            if (item && fs.get(item.dataset.path)?.type === "dir")
                go(item.dataset.path);
            else if (item)
                open_file(item.dataset.path);
        });
        $(".f-search", win).addEventListener("input", (event) => {
            files.filter = event.target.value.toLowerCase();
            render();
        });
        win.kit_go = go;
        on("fs", render);
        render();
    };

    // ===== App: browser =====

    const DEFAULT_TILES = [
        {name: "News", url: "poc://news", icon: "📰"},
        {name: "Video", url: "poc://video", icon: "▶"},
        {name: "Wiki", url: "poc://wiki", icon: "📖"},
        {name: "dotfiles", url: "poc://search?q=dotfiles", icon: "🔎"},
    ];

    function browser_page(url)
    {
        const browser = config.browser;
        const news = browser.news ?? {
            title: "Kernel 7.2 lands with a faster scheduler",
            lead: "The new release cuts wake-up latency on desktop workloads and brings better support for hybrid CPUs.",
            body: ["Benchmarks on a Fedora 44 workstation show smoother window dragging and shorter compile times on large C++ projects.",
                "Wayland compositors benefit the most: frame pacing is steadier when the CPU is busy with background builds."],
        };
        const video = browser.video ?? {title: "Building a desktop from scratch", channel: "dotfiles TV", background: "linear-gradient(135deg, #222, #444)"};
        const wiki = browser.wiki ?? {
            title: "Desktop environment",
            body: [["Overview", "A desktop environment bundles a window manager, panels, a file manager and settings into one coherent interface."],
                ["Styles", "Some users prefer a clean system look, others a terminal-only setup or a heavily themed desktop."]],
        };
        const query = url.startsWith("poc://search?q=") ? decodeURIComponent(url.slice(15)) : url;

        if (url === "poc://home") {
            return {
                title: "New tab",
                html: `<div class="b-home">${browser.hero ?? ""}<form class="b-search"><input class="k-input" name="q" placeholder="Search with ${esc(browser.engine ?? "Search")}" autocomplete="off"></form>`
                    + `<div class="b-tiles">${(browser.tiles ?? DEFAULT_TILES).map((tile) => `<a class="b-tile" data-href="${esc(tile.url)}"><span>${tile.icon}</span>${esc(tile.name)}</a>`).join("")}</div></div>`,
            };
        }
        if (url === "poc://news") {
            return {
                title: news.title,
                html: `<article class="b-article"><div class="k-muted">News · ${new Date().toLocaleDateString("en-GB")}</div><h1>${esc(news.title)}</h1>`
                    + `<p class="b-lead">${esc(news.lead)}</p>${news.body.map((text) => `<p>${esc(text)}</p>`).join("")}<p><a data-href="poc://wiki">Read more on the wiki →</a></p></article>`,
            };
        }
        if (url === "poc://video") {
            return {
                title: video.title,
                html: `<div class="b-video"><div class="b-player" style="background: ${esc(video.background)}"><button class="b-play" data-b="vplay">▶</button><div class="b-vbar"><i></i></div></div>`
                    + `<h2>${esc(video.title)}</h2><div class="k-muted">${esc(video.channel)} · 39K views</div>`
                    + `<div class="b-recos"><a data-href="poc://news">Related: ${esc(news.title)}</a><a data-href="poc://wiki">${esc(wiki.title)} explained</a></div></div>`,
            };
        }
        if (url === "poc://wiki") {
            return {
                title: wiki.title,
                html: `<article class="b-article"><h1>${esc(wiki.title)}</h1><div class="k-muted">From the POC wiki</div>`
                    + wiki.body.map(([heading, text]) => `<h3>${esc(heading)}</h3><p>${esc(text)}</p>`).join("") + "</article>",
            };
        }
        return {
            title: query,
            html: `<div class="b-results"><div class="k-muted">About 39,000 results for “${esc(query)}”</div>`
                + [[`${query} — Wiki`, "poc://wiki", `Everything about ${query}: history, usage and tips.`],
                    [`Latest news about ${query}`, "poc://news", news.lead],
                    [`${query} in 10 minutes (video)`, "poc://video", `${video.channel} explains ${query} step by step.`],
                    [`${query} - GitHub`, `poc://search?q=${encodeURIComponent(`${query} github`)}`, `Source code and dotfiles related to ${query}.`]]
                    .map(([title, href, text]) => `<div class="b-result"><a data-href="${esc(href)}">${esc(title)}</a><div class="b-url-hint">${esc(href)}</div><p>${esc(text)}</p></div>`).join("")
                + "</div>",
        };
    }

    APPS.browser = (id) => {
        const win = create_window(id, {
            title: "Browser", icon: icon("browser"), size: [920, 580], cls: "browser",
            body: "<div class=\"b-tabs\"></div><div class=\"b-bar\"><button class=\"k-btn\" data-b=\"back\">‹</button><button class=\"k-btn\" data-b=\"fwd\">›</button>"
                + "<button class=\"k-btn\" data-b=\"reload\">⟳</button><input class=\"k-input b-url\" spellcheck=\"false\"><button class=\"k-btn\" data-b=\"home\">⌂</button></div><div class=\"b-page\"></div>",
        });
        const tabs = [];
        let active = 0;
        const tab = () => tabs[active];

        function render()
        {
            const url = tab().history[tab().index];
            const page = browser_page(url);

            tab().title = page.title;
            $(".b-tabs", win).innerHTML = tabs.map((item, index) => {
                return `<button class="b-tab${index === active ? " is-on" : ""}" data-tab="${index}"><span>${esc(item.title ?? "New tab")}</span><i data-close-tab="${index}">×</i></button>`;
            }).join("") + "<button class=\"b-new\" data-b=\"new\" title=\"New tab\">+</button>";
            $(".b-url", win).value = url;
            $(".b-page", win).innerHTML = page.html;
            $(".b-page", win).scrollTop = 0;
            $(".win-title", win).textContent = `${page.title} — Browser`;
        }

        function add_tab(url = "poc://home")
        {
            tabs.push({history: [url], index: 0});
            active = tabs.length - 1;
            render();
        }

        function go(url)
        {
            tab().history = tab().history.slice(0, tab().index + 1);
            tab().history.push(url);
            tab().index++;
            render();
        }

        win.addEventListener("click", (event) => {
            const close_tab = event.target.closest("[data-close-tab]");
            const target = event.target.closest("[data-tab], [data-b], [data-href]");

            if (close_tab) {
                tabs.splice(Number(close_tab.dataset.closeTab), 1);
                active = Math.max(0, Math.min(active, tabs.length - 1));
                return tabs.length ? render() : add_tab();
            }
            if (!target)
                return;
            if (target.dataset.tab) {
                active = Number(target.dataset.tab);
                render();
            } else if (target.dataset.href) {
                go(target.dataset.href);
            } else if (target.dataset.b === "back" && tab().index > 0) {
                tab().index--;
                render();
            } else if (target.dataset.b === "fwd" && tab().index < tab().history.length - 1) {
                tab().index++;
                render();
            } else if (target.dataset.b === "reload") {
                render();
            } else if (target.dataset.b === "home") {
                go("poc://home");
            } else if (target.dataset.b === "new") {
                add_tab();
            } else if (target.dataset.b === "vplay") {
                target.textContent = target.closest(".b-player").classList.toggle("is-playing") ? "❚❚" : "▶";
            }
        });
        win.addEventListener("submit", (event) => {
            const query = new FormData(event.target).get("q");

            event.preventDefault();
            if (query)
                go(`poc://search?q=${encodeURIComponent(query)}`);
        });
        $(".b-url", win).addEventListener("keydown", (event) => {
            const value = event.target.value.trim();

            if (event.key === "Enter" && value)
                go(value.startsWith("poc://") ? value : `poc://search?q=${encodeURIComponent(value)}`);
        });
        win.kit_go = go;
        add_tab();
    };

    // ===== App: terminal =====

    const DEFAULT_LOGO = "  ╭────────╮\n  │  ╭──╮  │\n  │  │     │\n  │ ─┼──   │\n  │  │     │\n  │  ╵     │\n  ╰────────╯";
    const err = (text) => `<span class="t-err">${esc(text)}</span>`;
    const name_html = (entry) => `<span class="${entry.type === "dir" ? "t-dir" : `t-${entry.kind}`}">${esc(entry.name)}${entry.type === "dir" ? "/" : ""}</span>`;

    function tree(path, prefix = "", depth = 0)
    {
        const list = fs_list(path);

        return list.map((entry, index) => {
            const last = index === list.length - 1;
            const line = `${prefix}${last ? "└── " : "├── "}${name_html(entry)}`;
            const sub = entry.type === "dir" && depth < 2 ? tree(entry.path, prefix + (last ? "    " : "│   "), depth + 1) : "";

            return sub ? `${line}\n${sub}` : line;
        }).join("\n");
    }

    function neofetch()
    {
        const logo = (config.terminal.logo ?? DEFAULT_LOGO).split("\n");
        const palette = config.terminal.palette ?? ["#e5484d", "#f2c14e", "#5fd38d", "#5aa9ff", "#b48cff", "#9ccfd8"];
        const info = [
            `<span class="t-user">${esc(config.user)}@${esc(config.host)}</span>`,
            "─".repeat(config.user.length + config.host.length + 1),
            "<span class=\"t-accent\">OS</span>       Fedora Linux 44 x86_64",
            "<span class=\"t-accent\">Kernel</span>   7.2.11-200.fc44",
            "<span class=\"t-accent\">Shell</span>    zsh 5.9",
            `<span class="t-accent">WM</span>       poc-kit (${esc(config.layout)})`,
            `<span class="t-accent">Theme</span>    ${esc(config.name)}`,
            "<span class=\"t-accent\">CPU</span>      8 cores @ 3.80 GHz",
            "<span class=\"t-accent\">Memory</span>   9.8 GiB / 32 GiB",
            "",
            palette.map((color) => `<span style="background: ${color}">   </span>`).join(""),
        ];
        const width = Math.max(...logo.map((line) => line.length));

        return Array.from({length: Math.max(logo.length, info.length)}, (_, index) => {
            return `<span class="t-logo">${esc((logo[index] ?? "").padEnd(width))}</span>   ${info[index] ?? ""}`;
        }).join("\n");
    }

    const COMMANDS = {
        help: () => `<span class="t-muted">commands:</span> ${Object.keys({...COMMANDS, ...config.terminal.commands}).sort().join("  ")}`,
        ls: (args, term) => {
            const target = args.find((arg) => !arg.startsWith("-")) ?? ".";
            const path = fs_resolve(term.cwd, target);
            const node = fs.get(path);

            if (!node)
                return err(`ls: cannot access '${target}': No such file or directory`);
            if (node.type !== "dir")
                return esc(path.split("/").pop());
            if (!args.includes("-l"))
                return fs_list(path).map(name_html).join("  ");
            return fs_list(path).map((entry) => {
                return `${entry.type === "dir" ? "drwxr-xr-x" : "-rw-r--r--"}  ${esc(config.user)}  ${esc(String(entry.size ?? "4.0K").padStart(8))}  ${name_html(entry)}`;
            }).join("\n");
        },
        cd: (args, term) => {
            const path = fs_resolve(term.cwd, args[0] ?? "~");

            if (fs.get(path)?.type !== "dir")
                return err(`cd: no such file or directory: ${args[0]}`);
            term.cwd = path;
        },
        pwd: (args, term) => esc(term.cwd),
        cat: (args, term) => args.map((arg) => {
            const node = fs.get(fs_resolve(term.cwd, arg));

            if (!node)
                return err(`cat: ${arg}: No such file or directory`);
            return node.type === "dir" ? err(`cat: ${arg}: Is a directory`) : esc(node.content ?? `(binary ${node.kind} file)`);
        }).join("\n"),
        tree: (args, term) => {
            const path = fs_resolve(term.cwd, args[0] ?? ".");

            return `<span class="t-dir">${esc(short_path(path))}</span>\n${tree(path)}`;
        },
        echo: (args) => esc(args.join(" ")),
        clear: (args, term) => term.clear(),
        whoami: () => esc(config.user),
        hostname: () => esc(config.host),
        date: () => esc(new Date().toString()),
        uptime: () => `up ${Math.floor(performance.now() / 60000)} min, load average: 0.42, 0.39, 0.31`,
        history: (args, term) => term.history.map((line, index) => `${String(index + 1).padStart(4)}  ${esc(line)}`).join("\n"),
        neofetch,
        open: (args, term) => {
            const target = args[0] ?? "";

            if (APP_NAMES.includes(target))
                return void open(target);
            if (!fs.has(fs_resolve(term.cwd, target)))
                return err(`open: ${target || "?"}: no such app or file (apps: ${APP_NAMES.join(" ")})`);
            open_file(fs_resolve(term.cwd, target));
        },
        play: (args) => {
            open("music");
            play(args[0] ? Number(args[0]) - 1 : audio.index);
            return `♪ playing <span class="t-accent">${esc(track().title)}</span>`;
        },
        pause: () => (pause(), "paused"),
        next: () => (next(1), `♪ ${esc(track().title)}`),
        mkdir: (args, term) => {
            args.forEach((arg) => fs_add(fs_resolve(term.cwd, arg), {type: "dir"}));
            emit("fs");
        },
        touch: (args, term) => {
            args.filter((arg) => !fs.has(fs_resolve(term.cwd, arg))).forEach((arg) => fs_add(fs_resolve(term.cwd, arg), {type: "file", kind: "text", content: ""}));
            emit("fs");
        },
        rm: (args, term) => {
            args.filter((arg) => !arg.startsWith("-")).forEach((arg) => fs_remove(fs_resolve(term.cwd, arg)));
            emit("fs");
        },
        notify: (args) => notify(args.join(" ") || "Hello", "sent from the terminal", icon("terminal")),
        lock: () => scene("lock"),
        scene: (args) => (SCENES.some(([name]) => name === args[0]) ? scene(args[0]) : err(`scene: ${SCENES.map(([name]) => name).join(" | ")}`)),
        sudo: () => err(`${config.user} is not in the sudoers file. This incident will be reported.`),
        exit: (args, term) => set_state(term.win, "closed"),
    };

    function run(term, line)
    {
        const [name, ...args] = line.split(/\s+/);
        const command = config.terminal.commands?.[name] ?? COMMANDS[name];
        let result;

        if (!command)
            return term.print(err(`zsh: command not found: ${name}`));
        result = command(args, term, Kit);
        if (typeof result === "string" && result)
            term.print(result);
    }

    function complete(term, input)
    {
        const parts = input.value.split(" ");
        const last = parts.pop();
        let options = [];

        if (!parts.length) {
            options = Object.keys({...COMMANDS, ...config.terminal.commands}).filter((name) => name.startsWith(last)).map((name) => `${name} `);
        } else {
            const slash = last.lastIndexOf("/");
            const dir = last.slice(0, slash + 1);

            options = fs_list(fs_resolve(term.cwd, dir || ".")).filter((entry) => entry.name.startsWith(last.slice(slash + 1)))
                .map((entry) => dir + entry.name + (entry.type === "dir" ? "/" : ""));
        }
        if (options.length === 1)
            input.value = [...parts, options[0]].join(" ");
        else if (options.length > 1)
            term.print(options.map(esc).join("  "));
    }

    APPS.terminal = (id) => {
        const win = create_window(id, {
            title: "Terminal", icon: icon("terminal"), size: [720, 440], cls: "terminal",
            body: "<div class=\"t-screen\"><div class=\"t-out\"></div><label class=\"t-line\"><span class=\"t-prompt\"></span><input class=\"t-input\" spellcheck=\"false\" autocomplete=\"off\"></label></div>",
        });
        const out = $(".t-out", win);
        const input = $(".t-input", win);
        const screen = $(".t-screen", win);
        const term = {
            cwd: home(), history: [], position: 0, win,
            print: (markup) => {
                out.insertAdjacentHTML("beforeend", `<div>${markup}</div>`);
                screen.scrollTop = screen.scrollHeight;
            },
            clear: () => {
                out.innerHTML = "";
            },
        };
        const prompt = () => config.terminal.prompt?.(term, short_path(term.cwd))
            ?? `<span class="t-user">${esc(config.user)}@${esc(config.host)}</span>:<span class="t-path">${esc(short_path(term.cwd))}</span>$ `;
        const refresh = () => {
            $(".t-prompt", win).innerHTML = prompt();
            $(".win-title", win).textContent = config.terminal.title?.(term, short_path(term.cwd)) ?? `${config.user}@${config.host}: ${short_path(term.cwd)}`;
        };

        input.addEventListener("keydown", (event) => {
            if (event.key === "Enter") {
                const line = input.value.trim();

                term.print(`${prompt()}${esc(input.value)}`);
                input.value = "";
                if (line)
                    term.history.push(line);
                term.position = term.history.length;
                if (line)
                    run(term, line);
                refresh();
            } else if (event.key === "ArrowUp" || event.key === "ArrowDown") {
                event.preventDefault();
                term.position = Math.max(0, Math.min(term.history.length, term.position + (event.key === "ArrowUp" ? -1 : 1)));
                input.value = term.history[term.position] ?? "";
            } else if (event.key === "Tab") {
                event.preventDefault();
                complete(term, input);
            } else if (event.ctrlKey && event.key === "l") {
                event.preventDefault();
                term.clear();
            } else if (event.ctrlKey && event.key === "c") {
                term.print(`${prompt()}${esc(input.value)}^C`);
                input.value = "";
            }
        });
        screen.addEventListener("click", () => {
            if (!getSelection().toString())
                input.focus();
        });
        term.print(config.terminal.motd ?? `Welcome to <b>${esc(config.host)}</b> · type <span class="t-accent">help</span>, <span class="t-accent">neofetch</span> or <span class="t-accent">tree</span>`);
        (config.terminal.startup ?? []).forEach((line) => {
            term.print(`${prompt()}${esc(line)}`);
            run(term, line);
        });
        refresh();
    };

    // ===== Audio: a tiny synth playing the tracks of the style =====

    const audio = {ctx: null, master: null, lead: null, analyser: null, data: null, noise: null, timer: 0, step: 0, index: 0, playing: false, volume: 0.6};
    const track = () => config.tracks[audio.index];
    const parse_steps = (text) => [...text].map((char) => (char === "." ? null : char === "-" ? "-" : parseInt(char, 16)));

    function audio_init()
    {
        const ctx = audio.ctx ?? new (window.AudioContext || window.webkitAudioContext)();
        const samples = ctx.sampleRate;

        if (audio.ctx)
            return;
        audio.ctx = ctx;
        audio.master = ctx.createGain();
        audio.master.gain.value = audio.volume * 0.6;
        audio.lead = ctx.createBiquadFilter();
        audio.lead.type = "lowpass";
        audio.lead.frequency.value = 2600;
        audio.analyser = ctx.createAnalyser();
        audio.analyser.fftSize = 128;
        audio.data = new Uint8Array(audio.analyser.frequencyBinCount);
        audio.noise = ctx.createBuffer(1, samples, samples);
        audio.noise.getChannelData(0).forEach((_, index, data) => (data[index] = Math.random() * 2 - 1));
        audio.lead.connect(audio.master);
        audio.master.connect(audio.analyser);
        audio.analyser.connect(ctx.destination);
    }

    function tone(midi, time, duration, wave, gain, vibrato, output)
    {
        const ctx = audio.ctx;
        const osc = ctx.createOscillator();
        const amp = ctx.createGain();

        osc.type = wave;
        osc.frequency.value = 440 * 2 ** ((midi - 69) / 12);
        if (vibrato) {
            const lfo = ctx.createOscillator();
            const depth = ctx.createGain();

            lfo.frequency.value = 5.5;
            depth.gain.value = vibrato;
            lfo.connect(depth).connect(osc.frequency);
            lfo.start(time);
            lfo.stop(time + duration + 0.1);
        }
        amp.gain.setValueAtTime(0.0001, time);
        amp.gain.exponentialRampToValueAtTime(gain, time + 0.015);
        amp.gain.exponentialRampToValueAtTime(0.0001, time + duration);
        osc.connect(amp).connect(output);
        osc.start(time);
        osc.stop(time + duration + 0.05);
    }

    function drum(kind, time)
    {
        const ctx = audio.ctx;
        const amp = ctx.createGain();

        if (kind === "k") {
            const osc = ctx.createOscillator();

            osc.frequency.setValueAtTime(140, time);
            osc.frequency.exponentialRampToValueAtTime(45, time + 0.12);
            amp.gain.setValueAtTime(0.9, time);
            amp.gain.exponentialRampToValueAtTime(0.0001, time + 0.18);
            osc.connect(amp).connect(audio.master);
            osc.start(time);
            osc.stop(time + 0.2);
        } else {
            const source = ctx.createBufferSource();
            const filter = ctx.createBiquadFilter();

            source.buffer = audio.noise;
            filter.type = "highpass";
            filter.frequency.value = kind === "s" ? 1500 : 7000;
            amp.gain.setValueAtTime(kind === "s" ? 0.35 : 0.12, time);
            amp.gain.exponentialRampToValueAtTime(0.0001, time + (kind === "s" ? 0.16 : 0.05));
            source.connect(filter).connect(amp).connect(audio.master);
            source.start(time);
            source.stop(time + 0.2);
        }
    }

    function hold(steps, index)
    {
        let count = 1;

        while (count < steps.length && steps[(index + count) % steps.length] === "-")
            ++count;
        return count;
    }

    function tick()
    {
        const current = track();
        const length = current.lead.length;
        const index = audio.step % length;
        const time = audio.ctx.currentTime + 0.04;
        const step_time = 60 / current.bpm / 4;
        const lead = current.lead[index];
        const bass_index = current.bass ? index % current.bass.length : 0;
        const bass = current.bass?.[bass_index];
        const hit = current.drums?.[index % current.drums.length];

        if (typeof lead === "number")
            tone(current.scale[lead] ?? 60, time, hold(current.lead, index) * step_time * 0.95, current.wave ?? "sawtooth", current.gain ?? 0.14, current.vibrato ?? 0, audio.lead);
        if (typeof bass === "number")
            tone((current.scale[bass] ?? 48) - 24, time, hold(current.bass, bass_index) * step_time * 0.9, "triangle", 0.3, 0, audio.master);
        if (hit && hit !== ".")
            drum(hit, time);
        emit("step", {step: audio.step, index, length, note: lead, hit, track: current});
        if (hit === "k")
            emit("beat");
        if (++audio.step >= length * (current.loops ?? 4))
            next(1);
    }

    function play(index = audio.index)
    {
        const count = config.tracks.length;
        const wanted = ((index % count) + count) % count;

        if (!count)
            return;
        audio_init();
        audio.ctx.resume();
        if (wanted !== audio.index)
            audio.step = 0;
        audio.index = wanted;
        audio.playing = true;
        clearInterval(audio.timer);
        audio.timer = setInterval(tick, 60000 / track().bpm / 4);
        emit("music", {playing: true, index: audio.index, track: track()});
    }

    function pause()
    {
        clearInterval(audio.timer);
        audio.playing = false;
        emit("music", {playing: false, index: audio.index, track: track()});
    }

    function next(delta = 1)
    {
        const wanted = (audio.index + delta + config.tracks.length) % config.tracks.length;

        audio.step = 0;
        if (audio.playing) {
            play(wanted);
        } else {
            audio.index = wanted;
            emit("music", {playing: false, index: audio.index, track: track()});
        }
    }

    // one note on demand (piano roll preview, sound effects)
    function note(midi, length = 0.25, wave = "square", gain = 0.12)
    {
        audio_init();
        audio.ctx.resume();
        tone(midi, audio.ctx.currentTime + 0.01, length, wave, gain, 0, audio.lead);
    }

    function set_volume(value)
    {
        audio.volume = value;
        if (audio.master)
            audio.master.gain.value = value * 0.6;
    }

    function level()
    {
        let sum = 0;

        if (!audio.playing || !audio.analyser)
            return 0;
        audio.analyser.getByteFrequencyData(audio.data);
        for (const value of audio.data)
            sum += value;
        return sum / audio.data.length / 255;
    }

    // visualizers: every .m-viz or [data-kit="viz"] container gets its <i> bars driven by the analyser
    function frame()
    {
        const playing = audio.playing && audio.analyser;

        if (playing)
            audio.analyser.getByteFrequencyData(audio.data);
        for (const container of $$(".m-viz, [data-kit=\"viz\"]")) {
            const bars = container.children;

            for (let i = 0; i < bars.length; ++i) {
                const value = playing ? audio.data[Math.floor((i * audio.data.length * 0.7) / bars.length)] / 255 : 0.05;

                bars[i].style.height = `${Math.max(4, value * 100)}%`;
            }
        }
        requestAnimationFrame(frame);
    }

    // ===== App: music =====

    const duration = (item) => (item.lead.length * (item.loops ?? 4) * 60) / item.bpm / 4;
    const clock_text = (seconds) => `${Math.floor(seconds / 60)}:${pad(Math.floor(seconds % 60))}`;

    APPS.music = (id) => {
        const win = create_window(id, {
            title: "Music", icon: icon("music"), size: [420, 540], cls: "music",
            body: "<div class=\"m-now\"><div class=\"m-cover\"></div><div><div class=\"m-title\"></div><div class=\"m-artist k-muted\"></div></div></div>"
                + `<div class="m-viz">${"<i></i>".repeat(28)}</div><div class="m-seek"><i></i></div><div class="m-times k-muted"><span class="m-cur">0:00</span><span class="m-len">0:00</span></div>`
                + "<div class=\"m-ctl\"><button data-m=\"prev\">⏮</button><button data-m=\"play\" class=\"m-play\">▶</button><button data-m=\"next\">⏭</button></div><ol class=\"m-list\"></ol>",
        });

        function render()
        {
            const current = track();

            $(".m-title", win).textContent = current.title;
            $(".m-artist", win).textContent = current.artist;
            $(".m-cover", win).style.background = current.cover ?? "linear-gradient(135deg, var(--k-accent), #222)";
            $(".m-cover", win).textContent = current.cover_text ?? "";
            $(".m-play", win).textContent = audio.playing ? "❚❚" : "▶";
            $(".m-len", win).textContent = clock_text(duration(current));
            $(".m-list", win).innerHTML = config.tracks.map((item, index) => {
                return `<li><button data-track="${index}" class="${index === audio.index ? "is-cur" : ""}"><span>${esc(item.title)}</span><small>${esc(item.artist)} · ${clock_text(duration(item))}</small></button></li>`;
            }).join("");
        }

        win.addEventListener("click", (event) => {
            const button = event.target.closest("[data-m], [data-track]");

            if (!button)
                return;
            if (button.dataset.track)
                play(Number(button.dataset.track));
            else if (button.dataset.m === "play")
                audio.playing ? pause() : play();
            else
                next(button.dataset.m === "next" ? 1 : -1);
        });
        on("music", render);
        on("step", ({step, track: current}) => {
            $(".m-seek i", win).style.width = `${(step / (current.lead.length * (current.loops ?? 4))) * 100}%`;
            $(".m-cur", win).textContent = clock_text((step * 60) / current.bpm / 4);
        });
        render();
    };

    // ===== App: settings =====

    function set_wallpaper(index)
    {
        config.wallpapers.forEach((wall) => wall.cls && document.body.classList.remove(wall.cls));
        if (config.wallpapers[index]?.cls)
            document.body.classList.add(config.wallpapers[index].cls);
        for (const button of $$("[data-wall]"))
            button.classList.toggle("is-on", Number(button.dataset.wall) === index);
        emit("wallpaper", index);
    }

    APPS.settings = (id) => {
        const toggles = [
            {label: "Animations", key: "motion", on: true},
            {label: "Tiling layout (Hyprland-like)", key: "tile", on: config.layout === "tile"},
            {label: "Do not disturb", key: "dnd", on: false},
            ...config.toggles,
        ];
        const row = (label, control) => `<div class="s-row"><span>${esc(label)}</span>${control}</div>`;
        const win = create_window(id, {
            title: "Settings", icon: icon("settings"), size: [520, 560], cls: "settings",
            body: "<section><h3>Appearance</h3>"
                + (config.accents.length ? row("Accent", `<div class="s-swatches">${config.accents.map((color) => `<button class="s-swatch" data-accent="${color}" style="background: ${color}" title="${color}"></button>`).join("")}</div>`) : "")
                + (config.wallpapers.length ? row("Wallpaper", `<div class="s-walls">${config.wallpapers.map((wall, index) => `<button class="k-btn${index === 0 ? " is-on" : ""}" data-wall="${index}">${esc(wall.label)}</button>`).join("")}</div>`) : "")
                + "</section><section><h3>System</h3>"
                + toggles.map((item, index) => row(item.label, `<button class="s-switch${item.on ? " is-on" : ""}" data-toggle="${index}" aria-label="${esc(item.label)}"></button>`)).join("")
                + row("Volume", `<input class="s-volume" type="range" min="0" max="100" value="${audio.volume * 100}">`)
                + "</section><section><h3>About</h3>"
                + row("Device", `<span class="k-muted">${esc(config.host)}</span>`) + row("User", `<span class="k-muted">${esc(config.user)}</span>`)
                + row("Style", `<span class="k-muted">${esc(config.name)}</span>`) + row("Shell", "<span class=\"k-muted\">poc-kit 1.0</span>") + "</section>",
        });

        win.addEventListener("click", (event) => {
            const target = event.target.closest("[data-accent], [data-wall], [data-toggle]");

            if (!target)
                return;
            if (target.dataset.accent) {
                document.documentElement.style.setProperty("--k-accent", target.dataset.accent);
                emit("accent", target.dataset.accent);
            } else if (target.dataset.wall) {
                set_wallpaper(Number(target.dataset.wall));
            } else {
                const item = toggles[Number(target.dataset.toggle)];
                const value = target.classList.toggle("is-on");

                if (item.key === "motion")
                    document.body.classList.toggle("no-motion", !value);
                else if (item.key === "dnd")
                    state.dnd = value;
                else if (item.key === "tile")
                    set_layout(value ? "tile" : "float");
                if (item.cls)
                    document.body.classList.toggle(item.cls, value);
                item.run?.(value);
            }
        });
        $(".s-volume", win).addEventListener("input", (event) => set_volume(event.target.value / 100));
    };

    // ===== Init =====

    function build_chrome()
    {
        const scenebar = element(`<nav class="scenebar"><a href="index.html" title="All styles">⌂</a>${SCENES.map(([name, label], index) => {
            return `<button data-scene="${name}" title="${label} (key ${index + 1})"><b>${index + 1}</b><span>${label}</span></button>`;
        }).join("")}</nav>`);

        menu = element("<div class=\"ctx is-hidden\"></div>");
        document.body.append(scenebar, menu);
        build_lock();
        build_launcher();
    }

    function wire_events()
    {
        desk.addEventListener("pointerdown", (event) => {
            const win = event.target.closest(".win");
            const bar = event.target.closest(".win-bar");
            const grip = event.target.closest(".win-grip");

            if (!win || !windows.has(win.id))
                return;
            focus(win);
            if (config.layout !== "float" || event.button !== 0)
                return;
            if (bar && !event.target.closest("button, input, a") && !win.classList.contains("is-max"))
                drag(event, win, bar, false);
            else if (grip)
                drag(event, win, grip, true);
        });
        desk.addEventListener("dblclick", (event) => {
            const bar = event.target.closest(".win-bar");

            if (bar && !event.target.closest("button")) {
                bar.parentElement.classList.toggle("is-max");
                relayout();
            }
        });
        desk.addEventListener("contextmenu", (event) => {
            if (event.target.closest(".win, input, textarea"))
                return;
            event.preventDefault();
            show_menu(event);
        });
        document.addEventListener("click", (event) => {
            const target = event.target.closest("[data-act], [data-app], [data-scene], [data-task], [data-ctx]");

            if (!event.target.closest(".ctx"))
                hide_menu();
            if (!target)
                return;
            if (target.dataset.act && target.closest(".win-bar")) {
                const win = target.closest(".win");

                if (target.dataset.act === "max") {
                    win.classList.toggle("is-max");
                    relayout();
                } else {
                    set_state(win, target.dataset.act === "min" ? "min" : "closed");
                }
            } else if (target.dataset.app) {
                if (target.dataset.app === "launcher")
                    toggle_launcher();
                else
                    toggle(target.dataset.app);
            } else if (target.dataset.scene) {
                scene(target.dataset.scene);
            } else if (target.dataset.task) {
                toggle(target.dataset.task);
            } else if (target.dataset.ctx) {
                hide_menu();
                menu_items[Number(target.dataset.ctx)]?.run();
            }
        });
        document.addEventListener("keydown", (event) => {
            const typing = event.target.closest?.("input, textarea, [contenteditable]");
            const index = Number(event.key) - 1;

            if (event.key === "Escape") {
                toggle_launcher(false);
                hide_menu();
            }
            if (event.ctrlKey && event.code === "Space") {
                event.preventDefault();
                return toggle_launcher();
            }
            if (!lock_el.classList.contains("is-hidden"))
                lock_el.classList.add("is-awake");
            if (typing || event.ctrlKey || event.altKey || event.metaKey)
                return;
            if (Number.isInteger(index) && index >= 0 && index < SCENES.length)
                scene(SCENES[index][0]);
        });
        addEventListener("resize", relayout);
        addEventListener("error", (event) => notify("Script error", event.message, "⚠"));
    }

    function init(options)
    {
        config = {
            name: "POC", user: "tsukini", host: "fedora", layout: "float", desktop: [], scenes: {}, accents: [], wallpapers: [],
            lock: {}, browser: {}, files: {}, context: [], toggles: [], icons: {}, positions: {}, tracks: DEFAULT_TRACKS,
            ...options,
            terminal: {commands: {}, ...options.terminal},
            chrome: {min: "–", max: "□", close: "✕", ...options.chrome},
        };
        desk = $(".desk");
        for (const item of config.tracks) {
            if (typeof item.lead === "string")
                item.lead = parse_steps(item.lead);
            if (typeof item.bass === "string")
                item.bass = parse_steps(item.bass);
        }
        build_fs();
        document.body.classList.toggle("k-tile", config.layout === "tile");
        $$(".desk > .win").forEach(adopt);
        build_chrome();
        wire_events();
        update_clocks();
        setInterval(update_clocks, 1000);
        requestAnimationFrame(frame);
        // tiling transitions only after the first layout, so the page does not open with gliding windows
        setTimeout(() => document.body.classList.add("k-ready"), 500);
        const start = location.hash.replace(/^#(scene-)?/, "");

        scene(SCENES.some(([name]) => name === start) ? start : "desktop");
    }

    return {
        init, on, emit, open, close, toggle, spawn, maximize, active, set_layout, scene, notify, view, play, pause, next, note, level, track, element, esc,
        audio, state, windows, set_wallpaper,
        fs: {add: fs_add, get: (path) => fs.get(path), list: fs_list, resolve: fs_resolve, home},
    };
})();
