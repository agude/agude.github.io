# Mutation dispositions: `atproto.publish.x_sync_documents`

Record of the mutants that `make test-mutations-scripts MUTANTS='atproto.publish.x_sync_documents*'`
still reports as surviving. Python has no automated gate on this list yet.

Run: mutmut 3.8.1, quick profile, 234 mutants for `sync_documents`.

- Before the new tests: 163 killed, 70 survived, 1 timeout (mutant 192).
- After the new tests: 208 killed, 26 survived, 0 timeouts.

Mutants killed by the new tests are not listed here. They are in
`_scripts/tests/test_atproto_publish.py`.

Dispositions:

- `equivalent`: the mutant cannot change observable behavior.
- `out_of_scope`: the mutant changes wording only. The test suite asserts the
  identifying content (a path, URI, rule, or record name), but does not pin prose.

| Mutant                                         | Short mutation                                                        | Disposition  | Reason                                                                                                                          |
| ---------------------------------------------- | --------------------------------------------------------------------- | ------------ | ------------------------------------------------------------------------------------------------------------------------------- |
| `atproto.publish.x_sync_documents__mutmut_4`   | Wrap the empty-`publication_uri` message in `XX` markers              | out_of_scope | The rule text and the term `publication_uri` remain, and a test asserts the term.                                               |
| `atproto.publish.x_sync_documents__mutmut_9`   | Blank the `posts dir` label in `_require_dir`                         | out_of_scope | The stderr line still prints the missing path, which identifies the directory.                                                  |
| `atproto.publish.x_sync_documents__mutmut_12`  | Wrap the `posts dir` label in `XX` markers                            | out_of_scope | The stderr line still prints the missing path.                                                                                  |
| `atproto.publish.x_sync_documents__mutmut_13`  | Upper-case the `posts dir` label                                      | out_of_scope | The stderr line still prints the missing path.                                                                                  |
| `atproto.publish.x_sync_documents__mutmut_15`  | Blank the `books dir` label                                           | out_of_scope | The check still runs and the path is still printed. The missing-check gap is mutant 14, which is killed.                        |
| `atproto.publish.x_sync_documents__mutmut_18`  | Wrap the `books dir` label in `XX` markers                            | out_of_scope | The stderr line still prints the missing path.                                                                                  |
| `atproto.publish.x_sync_documents__mutmut_19`  | Upper-case the `books dir` label                                      | out_of_scope | The stderr line still prints the missing path.                                                                                  |
| `atproto.publish.x_sync_documents__mutmut_21`  | Wrap the `missing input directory` message in `XX` markers            | out_of_scope | The rule words remain, and a test asserts them.                                                                                 |
| `atproto.publish.x_sync_documents__mutmut_37`  | Change the separator between multiple errors for one file to `XX; XX` | out_of_scope | Each file name and error still appears. No test or runbook text pins the separator.                                             |
| `atproto.publish.x_sync_documents__mutmut_39`  | Replace the `AssertionError` message with `None`                      | equivalent   | Dead branch. `_collect_documents` yields a `None` record only together with a non-empty error list, and that list raises first. |
| `atproto.publish.x_sync_documents__mutmut_40`  | Wrap the `AssertionError` message in `XX` markers                     | equivalent   | Same dead branch as mutant 39.                                                                                                  |
| `atproto.publish.x_sync_documents__mutmut_41`  | Upper-case the `AssertionError` message                               | equivalent   | Same dead branch as mutant 39.                                                                                                  |
| `atproto.publish.x_sync_documents__mutmut_62`  | Wrap the publication no-cid message in `XX` markers                   | out_of_scope | The terms `getRecord` and `non-atomic` remain, and a test asserts them.                                                         |
| `atproto.publish.x_sync_documents__mutmut_65`  | Wrap the `non-atomic overwrite` phrase in `XX` markers                | out_of_scope | Same as mutant 62.                                                                                                              |
| `atproto.publish.x_sync_documents__mutmut_71`  | Wrap the dry-run publication plan line in `XX` markers                | out_of_scope | The plan text remains, and a test asserts it.                                                                                   |
| `atproto.publish.x_sync_documents__mutmut_89`  | Lower-case the publication-swap hint                                  | out_of_scope | The instruction to rerun is asserted. Capitalization is prose.                                                                  |
| `atproto.publish.x_sync_documents__mutmut_99`  | Wrap the `Updated publication record` line in `XX` markers            | out_of_scope | The success text remains, and a test asserts it.                                                                                |
| `atproto.publish.x_sync_documents__mutmut_119` | Default a remote record's missing `path` to `None` instead of `""`    | out_of_scope | A record with no path is orphaned either way. Only the printed orphan text differs, and that text is not a contract.            |
| `atproto.publish.x_sync_documents__mutmut_121` | Drop the default from `value.get("path")`                             | out_of_scope | Same as mutant 119.                                                                                                             |
| `atproto.publish.x_sync_documents__mutmut_124` | Default a missing `path` to `"XXXX"`                                  | out_of_scope | Same as mutant 119.                                                                                                             |
| `atproto.publish.x_sync_documents__mutmut_132` | Default a missing remote `cid` to `None` instead of `""`              | equivalent   | `None` and `""` are both falsy. The only consumer tests truthiness (`if not cid`) before use.                                   |
| `atproto.publish.x_sync_documents__mutmut_134` | Drop the default from `item.get("cid")`                               | equivalent   | Same as mutant 132.                                                                                                             |
| `atproto.publish.x_sync_documents__mutmut_164` | Wrap the listRecords no-cid message in `XX` markers                   | out_of_scope | The path and the words `non-atomic overwrite` remain.                                                                           |
| `atproto.publish.x_sync_documents__mutmut_222` | Pass `encoding=None` to `write_text`                                  | equivalent   | `json.dumps` defaults to `ensure_ascii=True`, so the data file is always ASCII. The codec cannot change its bytes.              |
| `atproto.publish.x_sync_documents__mutmut_224` | Drop `encoding=` from `write_text`                                    | equivalent   | Same as mutant 222.                                                                                                             |
| `atproto.publish.x_sync_documents__mutmut_233` | Change `"utf-8"` to `"UTF-8"`                                         | equivalent   | Python codec names are case-insensitive. The bytes are identical.                                                               |

## Timeout (mutant 192): resolved

Before the new tests, mutant 192 (`updated += 1` replaced by `updated = 1`) was
reported as a timeout. It is not a hang. The sync code has no loop that depends on the
counter. The mutant makes the summary line wrong, so the property test fails, and Hypothesis
then shrinks the failing sequence. The run took about 47 s, against 2.9 s for the unmutated
property file, and mutmut's timeout fired first.

The new example test `TestSummaryLine` asserts `created=0 updated=2 unchanged=0 orphaned=0`
for two updated documents. It kills mutant 192 without the shrink, and mutant 192 no
longer appears in `mutmut results`.
