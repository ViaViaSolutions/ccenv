import { cn } from "@/lib/utils";

export function Terminal({
  title,
  className,
  children,
}: {
  title?: string;
  className?: string;
  children: React.ReactNode;
}) {
  return (
    <div
      className={cn(
        "border-2 border-[var(--ink)] bg-[var(--term)] text-left",
        className,
      )}
    >
      <div className="flex items-center gap-2 border-b-2 border-[color-mix(in_oklab,var(--term-fg)_18%,transparent)] px-4 py-2.5">
        <span aria-hidden className="flex gap-1.5">
          <span className="size-2.5 rounded-full bg-[var(--spot)]" />
          <span className="size-2.5 rounded-full bg-[color-mix(in_oklab,var(--term-fg)_30%,transparent)]" />
          <span className="size-2.5 rounded-full bg-[color-mix(in_oklab,var(--term-fg)_30%,transparent)]" />
        </span>
        {title && (
          <span className="ml-1 font-[family-name:var(--font-mono)] text-xs tracking-wide text-[var(--term-dim)]">
            {title}
          </span>
        )}
      </div>
      <pre className="overflow-x-auto px-4 py-4 font-[family-name:var(--font-mono)] text-[13px] leading-relaxed text-[var(--term-fg)]">
        {children}
      </pre>
    </div>
  );
}

export function Prompt({ children }: { children: React.ReactNode }) {
  return (
    <>
      <span className="select-none text-[var(--term-dim)]">${" "}</span>
      <span className="text-[var(--term-fg)]">{children}</span>
    </>
  );
}

export function Comment({ children }: { children: React.ReactNode }) {
  return <span className="text-[var(--term-dim)]">{children}</span>;
}
