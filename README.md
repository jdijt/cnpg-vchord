# cnpg-vchord

Packages [VectorChord](https://github.com/supervc-stack/VectorChord) as a
[CloudNativePG extension image volume](https://cloudnative-pg.io/docs/current/imagevolume_extensions/),
so it can be mounted into CNPG-managed PostgreSQL clusters that use the
**minimal** base images (which ship without bundled extensions).

The image is built `FROM scratch` and carries only the extension's files, in the
layout CloudNativePG expects:

```
/lib/vchord.so              # dynamic_library_path (default /lib)
/share/extension/vchord*    # extension_control_path (default /share)
```

## Images

Published to `ghcr.io/jdijt/cnpg-vchord`, multi-arch (`amd64`, `arm64`), tagged:

```
ghcr.io/jdijt/cnpg-vchord:<vchord-version>-<build-timestamp>-<pg-major>-trixie
```

e.g. `ghcr.io/jdijt/cnpg-vchord:1.1.1-18-20260620183030-trixie`.

PostgreSQL majors 14–18 are built (VectorChord 1.1.x ships no PG 13 package).

## Usage

VectorChord requires the `vector` extension (pgvector), so mount both. With a
`ClusterImageCatalog` carrying the extension definitions, a cluster opts in by
name:

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
spec:
  imageCatalogRef:
    apiGroup: postgresql.cnpg.io
    kind: ClusterImageCatalog
    name: postgresql-minimal-trixie
    major: 18
  postgresql:
    shared_preload_libraries:
      - vchord
    extensions:
      - name: pgvector
      - name: vchord
```

Then create the extension in the database (it pulls in `vector` via `CASCADE`):

```sql
CREATE EXTENSION IF NOT EXISTS vchord CASCADE;
```

Alternatively, reference the image directly on the cluster without a catalog
entry:

```yaml
  postgresql:
    extensions:
      - name: vchord
        image:
          reference: ghcr.io/jdijt/cnpg-vchord:1.1.1-18-trixie
```

## Building locally

```sh
docker buildx build \
  --build-arg PG_MAJOR=18 \
  --build-arg VCHORD_VERSION=1.1.1 \
  --platform linux/amd64 \
  -f Containerfile .
```

## Licensing

The **packaging** in this repository (Containerfile, workflows, docs) is licensed
under [Apache-2.0](LICENSE).

The packaged software — **VectorChord** — is **not** covered by that license. It
is distributed under the **GNU Affero General Public License 3.0 (AGPL-3.0)** or **Elastic License v2 (ELv2)**. 
The container images produced here embed VectorChord binaries and are therefore subject one of these licenses for those components. 
See [NOTICE](NOTICE).