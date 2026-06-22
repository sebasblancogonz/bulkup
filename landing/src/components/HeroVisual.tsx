import { motion, useMotionValue, useSpring, useTransform, useReducedMotion } from 'motion/react';
import type { PointerEvent } from 'react';

/**
 * Floating phone mockup with a spring-based 3D tilt that tracks the
 * pointer. Decorative only — gated to fine-pointer devices and reduced
 * motion. Renders a real app screenshot inside the frame.
 */
export default function HeroVisual({ src, alt }: { src: string; alt: string }) {
  const reduce = useReducedMotion();
  const mx = useMotionValue(0);
  const my = useMotionValue(0);
  const spring = { stiffness: 150, damping: 18, mass: 0.6 };
  const rotateY = useSpring(useTransform(mx, [-0.5, 0.5], [-12, 12]), spring);
  const rotateX = useSpring(useTransform(my, [-0.5, 0.5], [10, -10]), spring);
  const glareBg = useTransform(
    mx,
    [-0.5, 0.5],
    [
      'radial-gradient(120px circle at 20% 18%, rgba(255,255,255,.12), transparent 60%)',
      'radial-gradient(120px circle at 80% 18%, rgba(255,255,255,.12), transparent 60%)',
    ],
  );

  function onMove(e: PointerEvent<HTMLDivElement>) {
    if (reduce || e.pointerType !== 'mouse') return;
    const r = e.currentTarget.getBoundingClientRect();
    mx.set((e.clientX - r.left) / r.width - 0.5);
    my.set((e.clientY - r.top) / r.height - 0.5);
  }
  function onLeave() {
    mx.set(0);
    my.set(0);
  }

  return (
    <div
      className="relative mx-auto"
      style={{ perspective: 1000 }}
      onPointerMove={onMove}
      onPointerLeave={onLeave}
    >
      <motion.div
        className={reduce ? '' : 'float'}
        style={{ rotateX, rotateY, transformStyle: 'preserve-3d' }}
      >
        <div className="relative mx-auto w-[280px] h-[580px] rounded-[2.5rem] border border-[var(--color-line)] bg-[var(--color-surface)] shadow-2xl shadow-black/60 overflow-hidden">
          {/* real app screenshot (its own status bar shows, so no fake notch) */}
          <img src={src} alt={alt} className="absolute inset-0 w-full h-full object-cover" loading="eager" />
          {/* moving glare */}
          {!reduce && (
            <motion.div className="absolute inset-0 pointer-events-none" style={{ background: glareBg }} />
          )}
        </div>
      </motion.div>
    </div>
  );
}
