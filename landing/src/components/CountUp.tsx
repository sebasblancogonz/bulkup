import { useEffect, useRef, useState } from 'react';
import { animate, useInView, useReducedMotion } from 'motion/react';

/**
 * Counts from 0 up to `to` when scrolled into view. SSR-safe: renders the
 * final value so no-JS users (and crawlers) see the real number; the
 * count-up only runs on hydration.
 */
export default function CountUp({ to, duration = 1.4 }: { to: number; duration?: number }) {
  const reduce = useReducedMotion();
  const ref = useRef<HTMLSpanElement>(null);
  const inView = useInView(ref, { once: true, margin: '-60px' });
  const [value, setValue] = useState(to);

  useEffect(() => {
    if (reduce) return;
    setValue(0);
  }, [reduce]);

  useEffect(() => {
    if (reduce || !inView) return;
    const controls = animate(0, to, {
      duration,
      ease: [0.16, 1, 0.3, 1],
      onUpdate: (v) => setValue(Math.round(v)),
    });
    return () => controls.stop();
  }, [inView, to, duration, reduce]);

  return <span ref={ref}>{value.toLocaleString()}</span>;
}
