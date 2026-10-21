<h1 align="center">
  <img width="3736" height="2508" alt="sos" src="https://github.com/user-attachments/assets/750bb727-b4ed-4373-829b-689a9a48df2e" />

</h1>
   <p align="center">
    <a href="https://github.com/Synergy-Tweaks/SynergyOS/releases" target="_blank"><img alt="Release" src="https://img.shields.io/github/release/Synergy-Tweaks/SynergyOS?style=for-the-badge&color=1A91FF" /></a>
    <a href="https://github.com/Synergy-Tweaks/SynergyOS/releases" target="_blank"><img alt="Downloads" src="https://img.shields.io/github/downloads/Synergy-Tweaks/SynergyOS/total?style=for-the-badge&color=1A91FF&label=Downloads" /></a>
    <a href="https://discord.gg/rpKVgutq6F" target="_blank"><img alt="Discord" src="https://img.shields.io/discord/1395215998646489211?style=for-the-badge&color=1A91FF&logo=discord&logoColor=white&label=Discord" /></a>
    <img alt="Supported Versions" src="https://img.shields.io/badge/Windows%2011%20%26%2010-1a91ff?style=for-the-badge&logo=windows" />
  </p>
<p align="center"> The ONLY Windows Modification Playbook that Your PC Will Ever Need designed to optimize performance, privacy, and usability.</p>

<p align="center">
  <a href="https://github.com/Synergy-Tweaks/SynergyOS" target="_blank">🌐 GitHub Repository</a>
  •
  <a href="https://github.com/Synergy-Tweaks/SynergyOS/discussions" target="_blank">💬 Discussions</a>
</p>

**Developed by [Kwanteks](https://github.com/kwanteks) and [Bry1k](https://github.com/bry1k)**

## What is SynergyOS?
SynergyOS is a comprehensive, performance-focused Windows modification playbook built on the [Ameliorated (AME) Wizard](https://amelabs.net/) framework. Designed to maximize system speed, reduce latency, and user privacy, it provides a streamlined and optimized Windows environment tailored for gamers, power users, and performance enthusiasts.

## Deployment

SynergyOS is distributed as an `.apbx` playbook using AME Wizard to apply to your windows installation.

1. Start with a clean, stock Windows ISO (22H2 through 26H2, LTSC supported).
2. Download AME Wizard from [amelabs.net](https://amelabs.net).
3. Load `SynergyOS.apbx` and follow the prompts.

> [!IMPORTANT]
> Only download `SynergyOS.apbx` from this repo or our official Discord. We are not responsible for modified or repackaged copies distributed elsewhere.

## Security options

Four of the checkboxes shown during setup trade Windows security for compatibility or
performance. All four are **unchecked by default** — nothing on this list is applied
unless you tick it.

| Option | What it does | Why you might not want it |
| --- | --- | --- |
| Disable Defender | Stops the Defender services and deletes its binaries | Irreversible without a repair install, and leaves the machine with no AV |
| Disable Exploit Mitigations | Forces DEP, ASLR, SEHOP and CFG off machine-wide | Applies to every process, not just games; most anti-cheats refuse to run |
| Disable User Account Control | `EnableLUA=0`, no elevation prompts | Everything you launch runs fully elevated, and UWP/Store apps stop working |
| Disable VBS / HVCI / Credential Guard | Turns off virtualisation-based security and LSA Protection | LSA Protection is what stops credential-dumping tools reading `lsass` |

Windows Update is paused (until 2038) by this playbook regardless of the options above.
The Windows Update page in Settings is left reachable so you can resume updates when
you want them. Make sure to reopen AME Wizard and click on `Run Again`.

## Contributing

Want to help fix a bug or build a new feature? Open the [Issues](https://github.com/Synergy-Tweaks/SynergyOS/issues) tab to see individual tickets, or check the [project board](https://github.com/orgs/Synergy-Tweaks/projects) for a status view of what's in progress. We appreciate every single person that helps improve SynergyOS. 

> [!TIP]
> Comment on the issue you want to work on before starting to work on it, so we can assign it to you to prevent ending up duplicating someone else's work.
> Make sure to read the [Ameliorated Documentations](https://docs.amelabs.net) before making any changes to any file in SynergyOS as this will help you learn more about how AME Playbooks work.

## Credits

- **Lead Developers:** Kwanteks, Bry1k & Chr
- **Framework:** [Amelabs / AME Wizard](https://amelabs.net)

## Connect

- **Business Email:** khanwbizz@gmail.com
- **Discord:** [Kwanteks](https://dsc.gg/kwanteks)
- **YouTube:** [youtube.com/@kwanteks](https://youtube.com/@kwanteks)

## Contributors

<a href="https://github.com/Synergy-Tweaks/SynergyOS/graphs/contributors" target="_blank"><img src="https://contrib.rocks/image?repo=Synergy-Tweaks/SynergyOS&columns=18" alt="Avatars of all contributors"></a>
