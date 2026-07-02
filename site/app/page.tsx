import { CopyButton } from "@/components/copy-button";
import { Comment, Prompt, Terminal } from "@/components/terminal";
import { ScrollReveal } from "@/components/scroll-reveal";
import { CustomCursor } from "@/components/custom-cursor";

const GITHUB_URL = "https://github.com/ViaViaSolutions/ccenv";
const INSTALL_CMD = "curl -fsSL https://ccenv.dev/install.sh | bash";

const COMMANDS = [
  { bin: "ccenv", sub: "use", args: "<name>", desc: "Rebind the current shell to an account (needs shell integration)." },
  { bin: "ccenv", sub: "run", args: "<name>", desc: "Launch a one-off session on an account." },
  { bin: "ccenv", sub: "list", args: "", desc: "Show every profile; ● marks the active shell." },
  { bin: "ccenv", sub: "current", args: "", desc: "Print the account this shell is on." },
  { bin: "ccenv", sub: "create", args: "<name>", desc: "Make a new profile; it inherits your setup." },
  { bin: "ccenv", sub: "login", args: "<name>", desc: "Sign a profile in via claude auth." },
  { bin: "ccenv", sub: "sync", args: "<name>", desc: "Re-copy settings.json / mcp_config.json and re-link any missing shared assets." },
  { bin: "ccenv", sub: "doctor", args: "", desc: "Health-check the CLI, credential store and integration." },
  { bin: "ccenv", sub: "rename", args: "<a> <b>", desc: "Rename a profile (guarded)." },
  { bin: "ccenv", sub: "remove", args: "<name>", desc: "Delete a profile (guarded; refuses default)." },
  { bin: "ccenv", sub: "update", args: "", desc: "Fetch the latest build from ccenv.dev and swap it in." },
  { bin: "ccenv", sub: "uninstall", args: "", desc: "Remove ccenv itself; --purge also deletes every profile." },
];

const INHERITANCE = [
  {
    num: "i",
    why: "Each profile gets its own config directory; ccenv points Claude Code at it through the CLAUDE_CONFIG_DIR environment variable.",
  },
  {
    num: "ii",
    why: "Because Claude Code keys credentials by config dir, two terminals on two profiles are two fully live accounts, with no clobbering.",
  },
  {
    num: "iii",
    why: "Your plugins, skills, commands, hooks and CLAUDE.md are symlinked into every profile; mutable config is copied so concurrent accounts never race.",
  },
  {
    num: "iv",
    why: "Your existing ~/.claude is the default profile. There's nothing to migrate.",
  },
];

const SECURITY = [
  {
    claim: "Stores zero secrets",
    detail: "Auth is delegated entirely to claude auth. Tokens stay in the OS credential store; ccenv never reads, writes or holds them.",
  },
  {
    claim: "Guarded removal",
    detail: "A profile path must be a real directory under $HOME, with no .. and no symlinks, before anything is deleted. default is never removable.",
  },
  {
    claim: "Injection-safe setup",
    detail: "Shell-rc edits are upserted atomically and profile names are restricted. Implementation: rc lines are built with printf %q; new dirs are created 0700, files 0600.",
  },
  {
    claim: "Tells you what's wrong",
    detail: "doctor checks the claude CLI, the credential store, shell integration, per-profile sign-in and broken links.",
  },
];

function SheetHead({ index, kicker, children }: { index: string; kicker: string; children: React.ReactNode }) {
  return (
    <div className="sheet-head">
      <span className="index" aria-hidden>{index}</span>
      <div>
        <p className="kicker mb-3">{kicker}</p>
        <h2 className="title">{children}</h2>
      </div>
    </div>
  );
}

export default function Home() {
  return (
    <div className="flex min-h-svh flex-col">
      <ScrollReveal />
      <CustomCursor />

      {/* ─── Masthead ─────────────────────────────────── */}
      <header className="masthead">
        <div className="masthead__inner wrap">
          <a href="/" className="masthead__brand" aria-label="ccenv home">
            ccenv
          </a>
          <nav className="masthead__nav" aria-label="Primary">
            <a href="#problem">Why</a>
            <a href="#capabilities">What it does</a>
            <a href="#how-it-works">How it works</a>
            <a href="#commands">Commands</a>
            <a href="#security">Security</a>
          </nav>
          <a href="#install-cmd" className="masthead__cta">
            <span>Install</span>
            <span aria-hidden>↓</span>
          </a>
        </div>
      </header>

      <main className="flex-1">
        {/* ─── Hero ───────────────────────────────────── */}
        <section className="sheet sheet--hero">
          <div className="wrap" data-reveal>
            <p className="kicker mb-8">A field tool for Claude Code</p>
            <h1 className="headline" style={{ maxWidth: "16ch" }}>
              One account per terminal, switched with{" "}
              a keystroke
            </h1>
            <p className="lede mt-8">
              Personal in one terminal, work in another, a client in a third, all
              signed in at the same time. Switching takes one command. Your
              current login is already the <code>default</code> profile, so
              there&apos;s nothing to set up.
            </p>

            <div className="mt-10 flex flex-wrap items-center gap-x-8 gap-y-4">
              <a className="cta-bar" href="#install-cmd">
                <span>Install ccenv</span>
                <svg viewBox="0 0 16 16" width="16" height="16" fill="none" stroke="currentColor" strokeWidth="1.8" aria-hidden>
                  <path d="M3 8 L13 8" />
                  <path d="M9 4 L13 8 L9 12" />
                </svg>
              </a>
            </div>

            <figure className="mt-16 max-w-3xl">
              <figcaption className="kicker mb-3">One shell, multiple accounts</figcaption>
              <Terminal title="zsh" className="shadow-[7px_7px_0_var(--ink)]">
                <Prompt>ccenv list</Prompt>
                {"\n"}
                <span style={{ color: "var(--spot)" }}>●</span>
                {" default    johndoe@gmail.com       max\n"}
                {"  work       me@company.com          team\n"}
                {"  client     "}
                <Comment>not signed in</Comment>
                {"\n\n"}
                <Comment>● = active in this shell</Comment>
              </Terminal>
            </figure>
          </div>
        </section>

        {/* ─── The Problem ────────────────────────────── */}
        <section className="sheet" id="problem">
          <div className="wrap" data-reveal>
            <SheetHead index="01" kicker="The problem">
              Switching accounts meant logging out, which clobbers the one login you had.
            </SheetHead>
            <p className="body" style={{ fontSize: "1.15rem" }}>
              Claude Code keeps one active login. Add a work account or a client and
              you&apos;re signing in and out all day, losing the session you were in.{" "}
              <code>ccenv</code> makes accounts concurrent, not just switchable:
              every terminal stays on its own account, with no interference.
            </p>
          </div>
        </section>

        {/* ─── Capabilities ───────────────────────────── */}
        <section className="sheet sheet--sink" id="capabilities">
          <div className="wrap" data-reveal>
            <SheetHead index="02" kicker="What it does">
              Two terminals. Two live accounts. Zero clobbering.
            </SheetHead>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-x-16 gap-y-12 mt-4">
              <div>
                <p className="kicker mb-4" style={{ color: "var(--ink-3)" }}>A · Per-shell isolation</p>
                <h3 className="guard__title mb-4" style={{ fontSize: "1.5rem" }}>Each terminal is its own account.</h3>
                <p className="body mb-4">
                  <code>use</code> changes only the current shell. <code>run</code>{" "}
                  scopes a single session and leaves the shell untouched after.
                </p>
                <p className="body">
                  Each profile keeps its own credential-store entry. Sessions
                  running side by side never touch each other&apos;s tokens.
                </p>
              </div>

              <div>
                <p className="kicker mb-4" style={{ color: "var(--ink-3)" }}>B · Credential handling</p>
                <h3 className="guard__title mb-4" style={{ fontSize: "1.5rem" }}>Tokens stay in the OS keychain.</h3>
                <p className="body mb-4">
                  ccenv doesn&apos;t store secrets. Tokens live in macOS Keychain
                  (or a per-profile credentials file on Linux and Windows), managed
                  by Claude Code through <code>claude auth</code>.
                </p>
                <p className="body">
                  <code>~/.ccenv</code> is 0700, config copies are 0600. Nothing
                  phones home, nothing lands in a flat file.
                </p>
              </div>
            </div>

            <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-3 mt-16">
              <Terminal title="Terminal A" className="shadow-[5px_5px_0_var(--ink)]">
                <Prompt>ccenv use work</Prompt>
                {"\n"}
                <Prompt>claude</Prompt>
                {"\n"}
                <Comment># runs as work</Comment>
              </Terminal>
              <Terminal title="Terminal B — same moment" className="shadow-[5px_5px_0_var(--ink)]">
                <Prompt>ccenv use default</Prompt>
                {"\n"}
                <Prompt>claude</Prompt>
                {"\n"}
                <Comment># runs as personal</Comment>
              </Terminal>
              <Terminal title="Terminal C — one-off" className="shadow-[5px_5px_0_var(--ink)]">
                <Prompt>ccenv run client \</Prompt>
                {"\n  "}
                <span style={{ color: "var(--term-fg)" }}>
                  -- -p &quot;summarize this repo&quot;
                </span>
                {"\n"}
                <Comment># shell untouched</Comment>
              </Terminal>
            </div>
          </div>
        </section>

        {/* ─── How It Works ───────────────────────────── */}
        <section className="sheet" id="how-it-works">
          <div className="wrap" data-reveal>
            <SheetHead index="03" kicker="How it works">
              One config dir per account. That&apos;s the whole trick.
            </SheetHead>

            <ol className="max-w-4xl">
              {INHERITANCE.map(({ num, why }) => (
                <li key={num} className="step">
                  <span className="step__num">{num}</span>
                  <p className="step__body">{why}</p>
                </li>
              ))}
            </ol>
          </div>
        </section>

        {/* ─── Commands ───────────────────────────────── */}
        <section className="sheet sheet--sink" id="commands">
          <div className="wrap" data-reveal>
            <SheetHead index="04" kicker="Reference">
              A small CLI you&apos;ll remember.
            </SheetHead>

            <table className="spec">
              <caption className="sr-only">ccenv commands</caption>
              <tbody>
                {COMMANDS.map(({ bin, sub, args, desc }) => (
                  <tr key={sub}>
                    <td className="spec__cmd">
                      <span className="spec__bin">{bin}</span>{" "}
                      <span className="spec__sub">{sub}</span>
                      {args && (
                        <>
                          {" "}
                          <span className="spec__arg">{args}</span>
                        </>
                      )}
                    </td>
                    <td className="spec__desc">{desc}</td>
                  </tr>
                ))}
              </tbody>
            </table>

            <p className="body mt-6" style={{ fontSize: "0.95rem", color: "var(--ink-3)", maxWidth: "none" }}>
              <code>use</code> and <code>unuse</code> run through the shell
              integration the installer adds to your rc; open a new terminal (or
              re-source it) once after installing. <code>ccenv help full</code>{" "}
              prints the complete reference, including <code>create</code> options
              like <code>--isolated</code> and <code>--no-login</code>.
            </p>
          </div>
        </section>

        {/* ─── Security ───────────────────────────────── */}
        <section className="sheet" id="security">
          <div className="wrap" data-reveal>
            <SheetHead index="05" kicker="Security">
              It holds none of your secrets.
            </SheetHead>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-x-14 gap-y-12">
              {SECURITY.map(({ claim, detail }, idx) => (
                <div key={claim} className="guard">
                  <div className="guard__stamp">
                    <span>{(idx + 1).toString().padStart(2, "0")}</span>
                  </div>
                  <h3 className="guard__title">{claim}</h3>
                  <p className="guard__body">{detail}</p>
                </div>
              ))}
            </div>
          </div>
        </section>

        {/* ─── Install / CTA ──────────────────────────── */}
        <section className="sheet sheet--sink">
          <div className="wrap" data-reveal>
            <p className="kicker mb-6">Install</p>
            <h2 className="headline" style={{ fontSize: "clamp(2.6rem, 6vw, 5rem)", maxWidth: "10ch" }}>
              One line. <span className="mark">Done.</span>
            </h2>
            <p className="lede mt-6 mb-10">
              Your current login becomes the default profile automatically. Create
              a second profile, open another terminal, and both accounts run side
              by side.
            </p>

            <div id="install-cmd" className="installer max-w-2xl scroll-mt-24">
              <pre>
                <span className="sigil">$ </span>
                {INSTALL_CMD}
              </pre>
              <CopyButton text={INSTALL_CMD} label="Copy install command" />
            </div>

            <p className="body mt-12 pt-5" style={{ fontSize: "0.95rem", color: "var(--ink-3)" }}>
              No clone, no build step. Needs{" "}
              <a
                href="https://claude.com/claude-code"
                className="underline decoration-[var(--spot)] underline-offset-4 hover:text-[var(--ink)]"
                style={{ color: "var(--ink-2)" }}
              >
                Claude Code
              </a>{" "}
              and <code>curl</code> on your PATH. macOS, Linux, Windows via Git
              Bash or WSL. Per-user, no sudo; re-run any time to update.
            </p>
          </div>
        </section>
      </main>

      {/* ─── Colophon ─────────────────────────────────── */}
      <footer className="colophon">
        <div className="colophon__row wrap">
          <div className="flex items-center gap-3">
            <span className="colophon__brand">ccenv</span>
            <span aria-hidden style={{ color: "var(--ink-3)" }}>·</span>
            <span style={{ color: "var(--ink-2)" }}>MIT · zero telemetry</span>
          </div>
          <nav className="flex flex-wrap items-center gap-6" aria-label="Footer">
            <a href={GITHUB_URL} target="_blank" rel="noopener">GitHub</a>


            <span aria-hidden style={{ color: "var(--ink-3)" }}>© {new Date().getFullYear()}</span>
          </nav>
        </div>
        
        <p className="colophon__made wrap">
          Made on Earth with <span className="heart" aria-hidden>♥</span>
          <span className="sr-only">love</span>
        </p>

        <div className="colophon__mark wrap" aria-hidden>
          <svg viewBox="0 0 1200 200" preserveAspectRatio="xMidYMid meet">
            <text
              x="600"
              y="168"
              textAnchor="middle"
              fontFamily="var(--font-display-family)"
              fontWeight="800"
              fontSize="230"
              letterSpacing="-10"
              fill="currentColor"
            >
              ccenv
            </text>
          </svg>
        </div>
      </footer>
    </div>
  );
}
