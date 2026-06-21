import { motion, useScroll, useSpring, useReducedMotion } from 'motion/react';

/** Thin accent bar at the top of the viewport tracking scroll depth. */
export default function ScrollProgress() {
  const reduce = useReducedMotion();
  const { scrollYProgress } = useScroll();
  const scaleX = useSpring(scrollYProgress, { stiffness: 120, damping: 30, mass: 0.3 });
  if (reduce) return null;
  return (
    <motion.div
      aria-hidden="true"
      className="fixed top-0 left-0 right-0 h-[2px] z-[60] origin-left bg-[var(--color-accent)]"
      style={{ scaleX }}
    />
  );
}
