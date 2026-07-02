"use client";

import { useState } from "react";
import { Check, Copy } from "lucide-react";

export function CopyButton({ text, label }: { text: string; label?: string }) {
  const [copied, setCopied] = useState(false);

  async function copy() {
    await navigator.clipboard.writeText(text);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  }

  return (
    <button
      onClick={copy}
      aria-label={copied ? "Copied" : (label ?? "Copy to clipboard")}
      className="inline-flex shrink-0 items-center justify-center size-11 border-2 border-[color-mix(in_oklab,var(--term-fg)_22%,transparent)] text-[var(--term-fg)] hover:bg-[var(--spot)] hover:border-[var(--spot)] hover:text-[var(--paper)] transition-colors"
    >
      {copied ? <Check className="size-4" aria-hidden /> : <Copy className="size-4" aria-hidden />}
    </button>
  );
}
