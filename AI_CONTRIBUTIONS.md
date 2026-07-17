# 🤖 AI Contributions

This project was built with no prior server experience, using several different AI tools at different stages. This file is here so that's honest and visible, not hidden. Each tool did a different job — none of them did all of it.

---

## Google AI Mode (Chrome / google.com search)

This is where the whole project started. After finishing an earlier hardware project, I had spare parts lying around and asked, basically as a one-off question, what I could do with them. The idea to turn the old Fujitsu laptop into a home server came from that answer. Later, this same tool (search AI mode in Chrome) was also used for the actual hands-on deployment — the step-by-step commands for Docker, Pi-hole, Caddy, and Immich came from back-and-forth sessions with it, including the troubleshooting when things broke.

## Google AI Studio (Gemini Flash, latest)

Used after the deployment was done, not during it. I fed it the raw chat exports and terminal logs from the whole process, and it turned that mess into the structured docs you're reading now (README, architecture docs, phase logs, troubleshooting write-ups). Its large context window is what made it possible to process everything from the deployment in one go instead of piecing it together by hand.

## ChatGPT

Used mainly for research and as a second opinion, not for hands-on deployment. I set it up on purpose to question my choices and push back rather than just agree with me, so it's been useful for catching gaps in my own reasoning before I acted on something.

## Claude

Used as the steady point through all of this — reviewing what the other tools produced, catching mistakes (like a firewall that looked configured in the docs but wasn't actually turned on), and helping edit and clean up the documentation itself. Also used for actually writing and fixing files directly, when it wasn't tokens-out from the other tools.

---

None of this was done by one AI end-to-end, and none of it was done without checking one tool's output against another (or against me actually running the commands and seeing what happened). Mistakes still made it through more than once — some of those are documented in `docs/troubleshooting/` on purpose, instead of quietly fixed and forgotten.
