import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Covenant Prime | Enforceable Agentic Finance",
  description: "Proof-gated execution for AI-managed tokenized securities.",
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
