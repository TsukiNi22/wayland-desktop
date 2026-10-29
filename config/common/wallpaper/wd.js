// wayland-desktop live wallpaper kit, shared by the wallpaper.html of every style (loaded by wd-wallpaper)
//   wd.canvas(id)     full screen 2D context (device pixel ratio, follows the window size)
//   wd.run(draw)      draw(t, dt) at 30 fps at most; ?t=<seconds> draws one still frame at that time
//   wd.levels         48 music levels 0-1 (cava through wdAudio), smoothed, 0 when nothing plays; ?demo fakes music
//   wd.bass / wd.mid / wd.high / wd.energy / wd.beat (1 on a kick, then decays)
//   wd.image(src)     an image, drawn with wd.cover(ctx, image, zoom, dx, dy)
// The body fades in over the still wallpaper (swaybg) below, then tells wd-wallpaper it is ready
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
    };
    const contexts = [];

    // levels from wd-wallpaper (cava, 0-1000)
    window.wdAudio = values => {
        for (let i = 0; i < BARS; i++) {
            state.raw[i] = Math.min(1, (values[i] || 0) / 1000);
        }
        state.lastAudio = performance.now();
    };

    // style switch: fade out before the next page
    window.wdLeave = () => {
        document.body.style.transition = "opacity 0.4s ease-in";
        document.body.style.opacity = "0";
    };

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

            if (dt >= step * 0.9) {
                last = now;
                t += Math.min(dt, 0.1);
                update(t, Math.min(dt, 0.1));
                draw(t, Math.min(dt, 0.1));
            }
            requestAnimationFrame(frame);
        };
        requestAnimationFrame(frame);
        document.body.style.opacity = "1";
        // wd-wallpaper removes the still wallpaper once the page has faded in
        setTimeout(() => window.webkit && webkit.messageHandlers.wd && webkit.messageHandlers.wd.postMessage("ready"), 1200);
    }

    function image(src) {
        const element = new Image();

        element.src = src;
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

    // small helpers for the pages
    const rand = seed => {
        let s = seed >>> 0;

        return () => {
            s = (s * 1664525 + 1013904223) >>> 0;
            return s / 4294967296;
        };
    };

    addEventListener("resize", resize);
    document.body.style.opacity = "0";
    document.body.style.transition = "opacity 0.8s ease-out";
    return Object.assign(state, { canvas, run, image, cover, rand });
})();
