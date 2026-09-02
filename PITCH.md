# Sources and Newsletter Studio for Flutter — Pitch

> Pitch reviewed: 2026-09-02 · Project state: see canonical sources below

This repository provides two native, provider-neutral Flutter presentation packages: a source-reading sidebar and a newsletter composition studio. It lets host products offer coherent source-to-draft experiences without coupling the UI packages to one inbox or delivery provider.

## Current state

Both packages and their unified Flutter Web demo are implemented with synthetic data and typed host hooks; real inbox access, provider networking, delivery, and hosted proof remain responsibilities of consuming products.

## Navigate

- Business truth: `shipglows_data/business/business.md`
- Product truth: `README.md`
- Current work: `not yet documented`
- Technical map: `not yet documented`
- Repository guide: `README.md`

## Boundaries

The packages are presentation components, not an email client, inbox renderer, credential owner, or newsletter delivery service.
