# Contributing

Contributions and corrections are welcome.

## Reporting issues

If you find a bug — a wrong DAX measure, SQL that produces unexpected results, or a web app feature that misbehaves — open an issue with:

- What you expected to happen
- What actually happened
- Steps to reproduce (which query, which dashboard page, which web app interaction)
- Your environment (PostgreSQL version, Power BI Desktop version, browser)

## Proposing changes

1. Fork the repo
2. Create a feature branch: `git checkout -b fix/something` or `feat/something`
3. Make focused changes — one fix or feature per PR
4. Update [`README.md`](README.md) if you change behaviour or add files
5. Open a pull request describing what changed and why

## Code style

**SQL.** Lowercase keywords are fine, but stay consistent within a file. Always alias tables. Always include `ORDER BY` when ordering matters to the answer.

**DAX.** Currency measures use `formatString: "$#,0"`. Percentages use `formatString: "0.0%"`. Avoid `CALCULATE([Measure], FilterTable[col] = value)` without verifying the filter actually propagates through the relationship chain.

**React.** Functional components, named exports for pages, default exports for components, hooks at the top of each component. Match the existing patterns in `web/`.

## Data

Don't add real patient data. The synthetic dataset is intentionally synthetic. If you extend the generator, keep names and values clearly fictional.
