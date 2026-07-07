import { motion, useReducedMotion } from 'motion/react';

/**
 * Headline that reveals word-by-word with a blur + rise. The full string
 * stays in the DOM (SEO-safe); we only wrap words in spans for staggering.
 */
export default function RevealText({ text, className = '' }: { text: string; className?: string }) {
  const reduce = useReducedMotion();
  const words = text.split(' ');

  if (reduce) return <span className={className}>{text}</span>;

  return (
    <span className={className} aria-label={text}>
      {words.map((word, i) => (
        <span key={i} className="inline-block overflow-hidden align-bottom" aria-hidden="true">
          <motion.span
            data-reveal
            className="inline-block"
            initial={{ y: '100%', opacity: 0, filter: 'blur(8px)' }}
            animate={{ y: '0%', opacity: 1, filter: 'blur(0px)' }}
            transition={{ duration: 0.8, delay: 0.15 + i * 0.07, ease: [0.16, 1, 0.3, 1] }}
          >
            {word}
          </motion.span>
          {i < words.length - 1 ? ' ' : ''}
        </span>
      ))}
    </span>
  );
}
