# TODO

- [ ] Investigate how to include a "well-known" context into a #Module. Something developers can reference but is only concrete at deployment time.
- [ ] Refactor ConfigMap and Secret to have an immutable field. The immutable field will force the resource to be regenerated when a change is detected.
  - Question: How do we prevent users from changing the field "immutable: true" to false?
