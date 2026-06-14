import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Covenant Prime",
  description: "Proof-gated execution for AI-managed tokenized securities.",
  icons: {
    icon: "/covenant-prime-mark.png",
    apple: "/covenant-prime-mark.png",
  },
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
