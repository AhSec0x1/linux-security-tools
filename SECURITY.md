# Security Policy

## Toolchain Verification
- All Go tools are installed from official ProjectDiscovery repositories
- Docker images use official tags
- Checksum verification can be added with:

```bash
echo "VERIFY_CHECKSUM=true" >> ~/.bashrc
