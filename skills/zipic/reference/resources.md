# Zipic Official Resources

Authoritative sources to consult when the user asks about Zipic itself (features, pricing, troubleshooting, format choice, automation, comparisons) rather than asking you to compress something. Fetch these on demand instead of guessing.

First identify the user's platform. Read Windows requirements, Microsoft Store/package installation and codec guidance for Windows; use macOS requirements and Apple/Raycast integration guidance for macOS. A shared page may contain platform-specific sections. Do not present macOS-only features or the ICNS format as Windows capabilities. For native Windows execution details, see [windows.md](windows.md).

## Top-level

| Resource              | URL                                  | Use for |
| --------------------- | ------------------------------------ | ------- |
| Marketing site        | https://zipic.app                    | Pricing, supported formats, system requirements, free-tier policy. |
| Documentation         | https://docs.zipic.app               | Feature-level how-tos. Bilingual (English / 简体中文). |
| **AI-friendly index** | https://zipic.app/llms.txt           | Curated index of every doc / blog / release as `.md` mirrors. Fetch this **first** when you need to discover the right page. |
| Full content snapshot | https://zipic.app/llms-full.txt      | Single-file digest of marketing + featured blog posts + recent releases (~75 KB). Useful for offline-style answering. |
| Sitemap               | https://zipic.app/sitemap-index.xml  | All indexed URLs. |

Each `docs.zipic.app/<path>/` page has a clean-markdown mirror at `zipic.app/docs/<path>.md` — fetch the `.md` form when you need clean text, the HTML form when linking the user.

## Documentation deep links

### Start Here

| Topic                | URL                                            |
| -------------------- | ---------------------------------------------- |
| Installation         | https://docs.zipic.app/started/installation/   |
| Introduction         | https://docs.zipic.app/started/introduction/   |
| User interface       | https://docs.zipic.app/started/ui/             |

### AI Support

| Topic                              | URL                                          |
| ---------------------------------- | -------------------------------------------- |
| AI & CLI integration (overview)    | https://docs.zipic.app/ai/overview/          |

### Guides

| Topic                                    | URL                                                                  |
| ---------------------------------------- | -------------------------------------------------------------------- |
| **Command Line Tool (`zipic` CLI)**      | https://docs.zipic.app/guides/zipic-cli/                             |
| Basic image compression                  | https://docs.zipic.app/guides/image-compression-basic/               |
| Choosing image formats                   | https://docs.zipic.app/guides/choosing-image-formats/                |
| Save options                             | https://docs.zipic.app/guides/configuring-save-options/              |
| Resizing                                 | https://docs.zipic.app/guides/resizing-images/                       |
| Folder monitoring / auto-compress (Pro)  | https://docs.zipic.app/guides/monitoring-directory-autocompression/  |
| Workflow integration                     | https://docs.zipic.app/guides/optimizing-workflow/                   |
| Raycast extension                        | https://docs.zipic.app/guides/using-raycast-extension/               |
| Activating Pro                           | https://docs.zipic.app/guides/activating/                            |

### Reference

| Topic                | URL                                                  |
| -------------------- | ---------------------------------------------------- |
| Recommended settings | https://docs.zipic.app/reference/recommended-settings/ |
| Use cases            | https://docs.zipic.app/reference/use-cases/          |

### Resources

| Topic                                | URL                                                    |
| ------------------------------------ | ------------------------------------------------------ |
| FAQ                                  | https://docs.zipic.app/resources/faq/                  |
| Troubleshooting (Debug Mode + logs)  | https://docs.zipic.app/resources/troubleshooting/      |
| Website resources                    | https://docs.zipic.app/resources/additional-resources/ |
| Affiliate program                    | https://docs.zipic.app/resources/affiliate-program/    |

## i18n

All 20 docs pages have a Chinese mirror at `https://docs.zipic.app/zh-cn/<same-path>/` (e.g. `https://docs.zipic.app/zh-cn/guides/zipic-cli/`). Use the Chinese URL when responding in 简体中文; the docs site also has a built-in language switcher.

## Discovery fallback

If a user question doesn't match any topic above, fetch `https://zipic.app/llms.txt` — it indexes 19 doc pages, 46 blog posts, and 30 release notes with a one-line description per entry, so you can find the right page without crawling.
