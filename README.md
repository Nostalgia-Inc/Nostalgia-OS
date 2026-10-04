# ***Nostalgia OS***

## Quick Links
- 📖 [Getting Started Guide](GETTING_STARTED.md) - New users start here
- 🏗️ [Build Instructions](BUILD_INSTRUCTIONS.md) - How to build and test
- 📚 [Implementation Summary](IMPLEMENTATION_SUMMARY.md) - What was built
- 🛣️ [Roadmap](ROADMAP.md) - Future plans
- 🤝 [Contributing](CONTRIBUTING.md) - How to contribute

## Purpose

This Operating System is built for custom ISO configurations of Nostalgia Systems hardware creations.


This OS will have multiple sub systems to install and boot from depending on the requirements and specifacations of the hardware installed on. 


# **Nostalgia CRT**

This image is built purposely built for the Lattepanda Delta 3 Single Board Computer. 

- System:
- [Lattepanda Delta 3] - https://www.lattepanda.com/lattepanda-3-delta
  - Specs
  - [Processor] - Intel® Celeron® N5105 - 2.0-2.9GHz Quad-Core, Four-Thread
  - [Co-Processor] - ATMEGA32U4
  - [Memory] - LPDDR4 8GB 2933MHz
  - [Storage] - 64GB eMMC
  - [Graphics] - Intel® UHD Graphics (Frequency: 450 – 800MHz)

- Base images:
- [Main][(https://github.com/ublue-os/main/)]
- [Bazzite][(https://bazzite.gg/)]

## **Current Modifications**

### **Nostalgia CRT** — Feature validation in progress

| Feature | Verified status |
| --- | --- |
| Custom default user | Configured in disk/ISO installer; a fresh installation must be tested. |
| Custom wallpaper | Startup fix and isolated regression tests pass; a fresh graphical boot must be tested. |
| Arduino IDE | Fresh build confirms `Packages not found: arduino`; installation and launcher need completion. |
| Custom Plymouth theme | Assets exist; the script plugin is missing from the fresh image and animation/integration need completion. |
| Custom GRUB theme | Theme file exists but is not activated; menu layout and boot integration need completion. |
| LattePanda power tweaks | Tuning script exists; service ordering and supported governor selection corrected; hardware results must be measured. |

The base is pinned to Bazzite Deck `44.20260929`; the CRT container builds successfully.
See
[feature completion proposal](FEATURE_COMPLETION_PLAN.md) and
[review and validation notes](REVIEW_NOTES.md) before treating an image as release-ready.

---

# **Nostalgia Arcade - In Development**

This image is meant for a standard system install on non-specific hardware.

## **Current Modifications**

### **Nostalgia Arcade** 🚧 IN PROGRESS
  - Custom Default User - [Planned]
  - Custom Default Wallpaper - [Planned]
  - Configure Custom Nostalgia ARCADE Plymouth Theme - [Planned]
  - Configure Custom GRUB Theme - [Planned]
  - Generic Hardware Support - [Planned]

