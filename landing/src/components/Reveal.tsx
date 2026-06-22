import { motion, useReducedMotion } from 'motion/react';
import type { ReactNode } from 'react';

type Variant = 'up' | 'blur' | 'left' | 'right' | 'scale';

const OUT = [0.16, 1, 0.3, 1] as const; // strong ease-out

function hidden(variant: Variant, y: number) {
  switch (variant) {
    case 'blur': return { opacity: 0, y, filter: 'blur(12px)' };
    case 'left': return { opacity: 0, x: -40 };
    case 'right': return { opacity: 0, x: 40 };
    case 'scale': return { opacity: 0, scale: 0.94 };
    default: return { opacity: 0, y };
  }
}

const shown = { opacity: 1, x: 0, y: 0, scale: 1, filter: 'blur(0px)' };

export default function Reveal({
  children,
  delay = 0,
  y = 24,
  variant = 'up',
  duration = 0.7,
  className,
}: {
  children: ReactNode;
  delay?: number;
  y?: number;
  variant?: Variant;
  duration?: number;
  className?: string;
}) {
  const reduce = useReducedMotion();
  if (reduce) return <div className={className}>{children}</div>;
  return (
    <motion.div
      className={className}
      data-reveal
      initial={hidden(variant, y)}
      whileInView={shown}
      viewport={{ once: true, margin: '-80px' }}
      transition={{ duration, delay, ease: OUT }}
    >
      {children}
    </motion.div>
  );
}
