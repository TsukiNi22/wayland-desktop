// wayland-desktop live wallpaper kit, shared by the wallpaper.html of every style (loaded by wd-wallpaper)
//   wd.canvas(id)     full screen 2D context (device pixel ratio, follows the window size)
//   wd.run(draw)      draw(t, dt) at up to 30 fps; ?t=<seconds> draws one still frame at that time
//   wd.fps            frames a second given by wd-wallpaper (wdPower): 24 on an empty desktop, 10 under windows,
//                     0 under a fullscreen window (paused: nothing is drawn)
//   wd.levels         48 music levels 0-1 (cava through wdAudio), smoothed, 0 when nothing plays; ?demo fakes music
//   wd.bass / wd.mid / wd.high / wd.energy / wd.beat (1 on a kick, then decays)
//   wd.image(src)     an image, drawn with wd.cover(ctx, image, zoom, dx, dy)
//   wd.mouse, wd.hit(rect), wd.clickable(rects)   pointer over the page; only the rects get the clicks (the rest of
//                     the wallpaper lets them through)
//   wd.radio, wd.radioCommand(action, extra)       state and control of the radio played by wd-wallpaper (mpv)
//   wd.player(), wd.marquee(...), wd.cursor(on)    the radio of the style drawn by the page, scrolling text, hand pointer
//                     (a page without its own player gets a small one when its radio is shown: wd-style radio show,
//                     its colors from wd.radioLook = { panel, border, fg, muted, accent, onAccent, font, mono, corner })
//   wd.video(key, { audio, loop })   a media of the page (radio.json "media": a clip made by wd-wallpaper), paused
//                     with the wallpaper; null until it is made
// The body fades in over the still wallpaper (or the previous page), then tells wd-wallpaper it is ready
"use strict";

const wd = (() => {
    const params = new URLSearchParams(location.search);
    const BARS = 48;
    const state = {
        bars: BARS,
        raw: new Float32Array(BARS),
        levels: new Float32Array(BARS),
        peaks: new Float32Array(BARS),
        bass: 0,
        mid: 0,
        high: 0,
        energy: 0,
        beat: 0,
        bassSlow: 0,
        width: innerWidth,
        height: innerHeight,
        demo: params.has("demo"),
        user: params.get("user") || "user",
        host: params.get("host") || "linux",
        info: { os: params.get("os") || "Linux", kernel: params.get("kernel") || "", shell: params.get("shell") || "sh" },
        still: params.has("t") ? parseFloat(params.get("t")) : null,
        lastAudio: -1e9,
        fps: 24,
        mouse: { x: -1, y: -1 },
        radio: { available: params.get("radio") === "1", playing: false, paused: false, title: "", index: 0, station: "",
            loop: false },
        station: null,
        radioLook: {},
    };
    const contexts = [];
    // the media of the page (videos), paused while the wallpaper doesn't show
    const videos = [];

    // levels from wd-wallpaper (cava, 0-1000)
    window.wdAudio = values => {
        for (let i = 0; i < BARS; i++) {
            state.raw[i] = Math.min(1, (values[i] || 0) / 1000);
        }
        state.lastAudio = performance.now();
    };

    // how much of the wallpaper shows (wd-wallpaper): the frame rate follows
    window.wdPower = fps => {
        state.fps = fps;
        for (const { element, loop } of videos) {
            if (fps <= 0 && !element.paused) {
                element.pause();
            } else if (fps > 0 && loop && element.paused) {
                element.play().catch(() => {});
            }
        }
    };

    // radio state and station of the style (radio.json + the tracks kept offline) from wd-wallpaper
    window.wdRadio = values => Object.assign(state.radio, values);
    window.wdStation = station => {
        state.station = station;
    };

    // the pointer over something to click
    function cursor(pointer) {
        document.body.style.cursor = pointer ? "pointer" : "default";
    }

    // message to wd-wallpaper (nothing outside of it)
    function post(message) {
        if (window.webkit && webkit.messageHandlers.wd) {
            webkit.messageHandlers.wd.postMessage(JSON.stringify(message));
        }
    }

    // the only parts of the wallpaper that take the clicks: rects {x, y, w, h} in page pixels (the small radio adds its own)
    let pageRects = [];
    let radioRect = null;

    function clickable(rects) {
        pageRects = rects;
        post({ type: "input", rects: rects.concat(radioRect ? [radioRect] : [])
            .map(r => [Math.floor(r.x), Math.floor(r.y), Math.ceil(r.w), Math.ceil(r.h)]) });
    }

    function hit(rect) {
        const { x, y } = state.mouse;

        return x >= rect.x && x <= rect.x + rect.w && y >= rect.y && y <= rect.y + rect.h;
    }

    // play (station, index), toggle, next, prev, stop
    function radioCommand(action, extra = {}) {
        post(Object.assign({ type: "radio", action: action }, extra));
    }

    function demo(t) {
        const kick = Math.max(0, 1 - ((t * 2) % 1) * 3);

        for (let i = 0; i < BARS; i++) {
            const wave = 0.5 + 0.5 * Math.sin(t * 2.3 + i * 0.37) * Math.cos(t * 0.7 + i * 0.11);

            state.raw[i] = Math.min(1, (0.25 + 0.55 * wave) * (1.1 - i / BARS * 0.7) + (i < 6 ? kick * 0.5 : 0));
        }
    }

    function average(from, to) {
        let sum = 0;

        for (let i = from; i < to; i++) {
            sum += state.levels[i];
        }
        return sum / (to - from);
    }

    function update(t, dt) {
        const k = 1 - Math.exp(-dt * 16);

        if (state.demo) {
            demo(t);
        } else if (performance.now() - state.lastAudio > 300) {
            state.raw.fill(0);
        }
        for (let i = 0; i < BARS; i++) {
            state.levels[i] += (state.raw[i] - state.levels[i]) * k;
            state.peaks[i] = Math.max(state.levels[i], state.peaks[i] - dt * 0.6);
        }
        state.bass = average(0, 6);
        state.mid = average(6, 24);
        state.high = average(24, BARS);
        state.energy = average(0, BARS);
        state.bassSlow += (state.bass - state.bassSlow) * (1 - Math.exp(-dt * 2.5));
        state.beat = Math.max(state.beat * Math.exp(-dt * 7), state.bass - state.bassSlow > 0.1 ? 1 : 0);
    }

    function resize() {
        const dpr = window.devicePixelRatio || 1;

        state.width = innerWidth;
        state.height = innerHeight;
        for (const ctx of contexts) {
            ctx.canvas.width = Math.round(innerWidth * dpr);
            ctx.canvas.height = Math.round(innerHeight * dpr);
            ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
        }
    }

    function canvas(id) {
        let element = document.getElementById(id);

        if (!element) {
            element = document.createElement("canvas");
            element.id = id;
            document.body.appendChild(element);
        }
        contexts.push(element.getContext("2d"));
        resize();
        return contexts[contexts.length - 1];
    }

    function run(draw, fps = 30) {
        const step = 1 / fps;
        let t = 0;
        let last = performance.now();

        if (state.still !== null) {
            // still frame: play the first seconds at once so the particles and the smoothing settle
            for (t = 0; t < state.still; t += step) {
                update(t, step);
                draw(t, step);
            }
            document.body.style.transition = "none";
            document.body.style.opacity = "1";
            window.wdReady = true;
            return;
        }
        const frame = now => {
            const dt = (now - last) / 1000;

            // paused: no frame at all until it shows again (checked 4 times a second)
            if (state.fps <= 0) {
                last = now;
                setTimeout(() => requestAnimationFrame(frame), 250);
                return;
            }
            if (dt >= 0.9 / Math.min(fps, state.fps)) {
                last = now;
                t += Math.min(dt, 0.1);
                update(t, Math.min(dt, 0.1));
                draw(t, Math.min(dt, 0.1));
                drawRadio(t);
            }
            requestAnimationFrame(frame);
        };
        requestAnimationFrame(frame);
        document.body.style.opacity = "1";
        // wd-wallpaper removes the still wallpaper (or the previous page) once this one has faded in
        setTimeout(() => post({ type: "ready" }), 1200);
    }

    function image(src) {
        const element = new Image();

        element.src = src;
        return element;
    }

    // a media of the page: a <video> (muted unless audio), looping or not, paused with the wallpaper
    function video(key, options = {}) {
        const src = state.station && state.station.media ? state.station.media[key] : null;

        if (!src) {
            return null;
        }
        const element = document.createElement("video");

        element.src = src;
        element.muted = !options.audio;
        element.loop = !!options.loop;
        element.playsInline = true;
        element.preload = "auto";
        // in the document (tiny, behind the page): WebKit only runs and paints a video that is in it
        Object.assign(element.style, { position: "fixed", left: "0", top: "0", width: "2px", height: "2px", opacity: "0.01",
            zIndex: "-1", pointerEvents: "none" });
        document.body.appendChild(element);
        videos.push({ element: element, loop: !!options.loop });
        if (options.loop && state.fps > 0) {
            element.play().catch(() => {});
        }
        return element;
    }

    // the image fills the screen (crop), zoomed and moved by a few pixels
    function cover(ctx, element, zoom = 1, dx = 0, dy = 0) {
        if (!element.complete || !element.naturalWidth) {
            return;
        }
        const scale = Math.max(state.width / element.naturalWidth, state.height / element.naturalHeight) * zoom;
        const w = element.naturalWidth * scale;
        const h = element.naturalHeight * scale;

        ctx.drawImage(element, (state.width - w) / 2 + dx, (state.height - h) / 2 + dy, w, h);
    }

    // text scrolling inside <width> when it is too long
    function marquee(ctx, text, x, y, width, t) {
        const size = ctx.measureText(text).width;

        if (size <= width) {
            ctx.fillText(text, x, y);
            return;
        }
        const gap = 60;
        const offset = (t * 40) % (size + gap);

        ctx.save();
        ctx.beginPath();
        ctx.rect(x, y - 40, width, 80);
        ctx.clip();
        ctx.fillText(text, x - offset, y);
        ctx.fillText(text, x - offset + size + gap, y);
        ctx.restore();
    }

    // The radio drawn by the page: player() plays the station of the style (its radio.json and the user's tracks, given
    // by wd-wallpaper with the tracks kept offline); the page draws its decor, then player.buttons(ctx, x, y, size,
    // colors) (previous, play / pause, next, stop, loop the track, save it offline (a save dialog) or back online,
    // import audio files (a dialog)), the clicks are handled here
    let ownPlayer = false;

    function player(embedded = false) {
        ownPlayer = ownPlayer || !embedded;
        const self = {
            index: 0,
            rects: [],
            actions: ["prev", "play", "next", "stop", "loop", "offline", "import"],
            tracks: () => (state.station ? state.station.tracks : []),
            playing: () => state.radio.playing && state.station !== null && state.radio.station === state.station.station,
            position: () => (self.playing() ? state.radio.index : self.index) % Math.max(1, self.tracks().length),
            current: () => self.tracks()[self.position()] || { title: "\u2026", subtitle: "", cached: false },
            title: () => {
                const track = self.current();

                return self.playing() && state.radio.title ? state.radio.title
                    : track.title + (track.subtitle ? `  \u2014  ${track.subtitle}` : "");
            },
            status: () => {
                if (!state.radio.available && !self.current().cached) {
                    return "needs mpv + yt-dlp";
                }
                if (self.current().downloading) {
                    return "\u2913  downloading\u2026";
                }
                if (!self.playing()) {
                    return self.current().cached ? "\u25b6  click play  \u00b7  offline" : "\u25b6  click play";
                }
                return state.radio.paused ? "\u275a\u275a  paused" : "\u25cf  on air";
            },
            act: action => {
                const count = Math.max(1, self.tracks().length);

                if (action === "play" && self.playing()) {
                    radioCommand("toggle");
                } else if (action === "play" && state.station) {
                    radioCommand("play", { station: state.station.station, index: self.index });
                    Object.assign(state.radio, { playing: true, station: state.station.station, paused: false,
                        index: self.index, title: "" });
                } else if (action === "stop") {
                    radioCommand("stop");
                } else if (action === "offline" && state.station) {
                    radioCommand("offline", { station: state.station.station, index: self.position() });
                } else if (action === "import" && state.station) {
                    radioCommand("import", { station: state.station.station });
                } else if (action === "loop") {
                    if (self.playing()) {
                        radioCommand("loop");
                        state.radio.loop = !state.radio.loop;
                    }
                } else if (self.playing()) {
                    radioCommand(action);
                } else {
                    self.index = (self.index + (action === "next" ? 1 : count - 1)) % count;
                }
            },
            buttons: (ctx, x, y, size, colors) => {
                self.rects = self.actions.map((action, i) => ({ action: action, x: x + i * size * 2.6, y: y, w: size * 2, h: size * 2 }));
                for (const rect of self.rects) {
                    const cx = rect.x + size;
                    const cy = rect.y + size;
                    const main = rect.action === "play";
                    const over = hit(rect);

                    const on = rect.action === "loop" && self.playing() && state.radio.loop;

                    ctx.fillStyle = main || on ? colors.accent : (over ? colors.hover : colors.button);
                    ctx.beginPath();
                    ctx.arc(cx, cy, size * (over ? 1.08 : 1), 0, Math.PI * 2);
                    ctx.fill();
                    ctx.fillStyle = main || on ? colors.onAccent : colors.icon;
                    icon(ctx, rect.action === "play" && self.playing() && !state.radio.paused ? "pause"
                        : (rect.action === "offline" ? self.keeping() : rect.action), cx, cy, size * 0.42);
                }
            },
        };

        // the offline button: a check when the track is kept offline, dots while it downloads, else an arrow down
        self.keeping = () => {
            const track = self.current();

            return track.downloading ? "busy" : (track.offline && track.cached ? "saved" : "download");
        };
        addEventListener("click", event => {
            const target = self.rects.find(rect => event.clientX >= rect.x && event.clientX <= rect.x + rect.w
                && event.clientY >= rect.y && event.clientY <= rect.y + rect.h);

            if (target) {
                self.act(target.action);
            }
        });
        return self;
    }

    // shapes of the radio buttons, centered on (x, y)
    function icon(ctx, name, x, y, r) {
        const triangle = (from, to) => {
            ctx.beginPath();
            ctx.moveTo(x + from * r, y - r);
            ctx.lineTo(x + to * r, y);
            ctx.lineTo(x + from * r, y + r);
            ctx.closePath();
            ctx.fill();
        };

        if (name === "play") {
            triangle(-0.6, 0.9);
        } else if (name === "pause") {
            ctx.fillRect(x - r * 0.75, y - r, r * 0.55, r * 2);
            ctx.fillRect(x + r * 0.2, y - r, r * 0.55, r * 2);
        } else if (name === "next") {
            triangle(-0.9, 0.4);
            ctx.fillRect(x + r * 0.45, y - r, r * 0.3, r * 2);
        } else if (name === "prev") {
            triangle(0.9, -0.4);
            ctx.fillRect(x - r * 0.75, y - r, r * 0.3, r * 2);
        } else if (name === "loop") {
            ctx.save();
            ctx.strokeStyle = ctx.fillStyle;
            ctx.lineWidth = r * 0.28;
            ctx.beginPath();
            ctx.arc(x, y, r * 0.72, -0.3, Math.PI * 1.55);
            ctx.stroke();
            ctx.restore();
            ctx.beginPath();
            ctx.moveTo(x + r * 0.95, y - r * 0.55);
            ctx.lineTo(x + r * 0.35, y - r * 0.05);
            ctx.lineTo(x + r * 0.35, y - r * 0.95);
            ctx.closePath();
            ctx.fill();
        } else if (name === "import") {
            ctx.fillRect(x - r * 0.16, y - r * 0.85, r * 0.32, r * 1.7);
            ctx.fillRect(x - r * 0.85, y - r * 0.16, r * 1.7, r * 0.32);
        } else if (name === "download") {
            ctx.fillRect(x - r * 0.18, y - r, r * 0.36, r * 1.1);
            ctx.beginPath();
            ctx.moveTo(x - r * 0.7, y - r * 0.05);
            ctx.lineTo(x + r * 0.7, y - r * 0.05);
            ctx.lineTo(x, y + r * 0.65);
            ctx.closePath();
            ctx.fill();
            ctx.fillRect(x - r * 0.85, y + r * 0.8, r * 1.7, r * 0.25);
        } else if (name === "saved") {
            ctx.save();
            ctx.strokeStyle = ctx.fillStyle;
            ctx.lineWidth = r * 0.36;
            ctx.lineCap = "round";
            ctx.lineJoin = "round";
            ctx.beginPath();
            ctx.moveTo(x - r * 0.7, y);
            ctx.lineTo(x - r * 0.15, y + r * 0.55);
            ctx.lineTo(x + r * 0.75, y - r * 0.55);
            ctx.stroke();
            ctx.restore();
        } else if (name === "busy") {
            for (let i = 0; i < 3; i++) {
                ctx.globalAlpha = 0.35 + 0.65 * (Math.floor(performance.now() / 250) % 3 === i ? 1 : 0);
                ctx.beginPath();
                ctx.arc(x + (i - 1) * r * 0.7, y, r * 0.24, 0, Math.PI * 2);
                ctx.fill();
            }
            ctx.globalAlpha = 1;
        } else {
            ctx.fillRect(x - r * 0.75, y - r * 0.75, r * 1.5, r * 1.5);
        }
    }

    // The small radio of a page without its own: a panel in a corner when the radio of the style is shown
    let builtIn = null;
    let radioLayer = null;

    function drawRadio(t) {
        const shown = !ownPlayer && state.station && state.station.shown;

        if (!shown) {
            if (radioRect) {
                radioRect = null;
                radioLayer.clearRect(0, 0, state.width, state.height);
                builtIn.rects = [];
                clickable(pageRects);
            }
            return;
        }
        builtIn = builtIn || player(true);
        if (!radioLayer) {
            radioLayer = canvas("wd-radio");
            Object.assign(radioLayer.canvas.style, { position: "fixed", inset: "0", width: "100%", height: "100%",
                zIndex: "5", pointerEvents: "none" });
        }
        const look = Object.assign({ panel: "rgba(12, 14, 18, 0.86)", border: "rgba(255, 255, 255, 0.16)", fg: "#e9edf2",
            muted: "#98a2b0", accent: "#5aa9ff", onAccent: "#0e1217", font: '"Adwaita Sans", sans-serif',
            mono: '"JetBrains Mono", monospace', corner: 14 }, state.radioLook);
        const w = 420;
        const h = 116;
        const x = 40;
        const y = state.height - h - 40;
        const g = radioLayer;

        if (!radioRect || radioRect.x !== x || radioRect.y !== y) {
            radioRect = { x: x, y: y, w: w, h: h };
            clickable(pageRects);
        }
        g.clearRect(0, 0, state.width, state.height);
        g.fillStyle = look.panel;
        g.strokeStyle = look.border;
        g.lineWidth = 1;
        g.beginPath();
        g.roundRect(x, y, w, h, look.corner);
        g.fill();
        g.stroke();
        g.font = `700 11px ${look.mono}`;
        g.fillStyle = look.accent;
        g.fillText((state.station.name || "RADIO").toUpperCase(), x + 18, y + 24);
        g.fillStyle = look.muted;
        g.fillText(builtIn.status(), x + 18 + g.measureText((state.station.name || "RADIO").toUpperCase()).width + 16, y + 24);
        g.font = `600 15px ${look.font}`;
        g.fillStyle = look.fg;
        marquee(g, builtIn.title(), x + 18, y + 50, w - 36, t);
        builtIn.buttons(g, x + 18, y + 66, 14, { accent: look.accent, onAccent: look.onAccent,
            button: "rgba(255, 255, 255, 0.08)", hover: "rgba(255, 255, 255, 0.2)", icon: look.fg });
        cursor(builtIn.rects.some(hit));
    }

    // small helpers for the pages
    const rand = seed => {
        let s = seed >>> 0;

        return () => {
            s = (s * 1664525 + 1013904223) >>> 0;
            return s / 4294967296;
        };
    };

    addEventListener("resize", resize);
    // errors of the page in the log of wd-wallpaper
    addEventListener("error", event => post({ type: "log", text: `${event.message} (${event.filename}:${event.lineno})` }));
    addEventListener("mousemove", event => Object.assign(state.mouse, { x: event.clientX, y: event.clientY }));
    document.addEventListener("mouseleave", () => Object.assign(state.mouse, { x: -1, y: -1 }));
    document.body.style.opacity = "0";
    document.body.style.transition = "opacity 0.9s ease-out";
    return Object.assign(state, { canvas, run, image, video, cover, rand, clickable, hit, radioCommand, marquee, player,
        cursor });
})();
