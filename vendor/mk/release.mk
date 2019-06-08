bump-version: ## Set a new version for the project. Set VERSION=x.y.z
	@echo "--- $@"
	@if [ -z "$(strip $(VERSION))" ]; then \
		echo "xxx usage: make bump-version VERSION=1.2.3" >&2; \
		echo "xxx Missing required value: VERSION" >&2; \
		exit 1; \
	fi
	@echo "  - Updating: [README.md, install.sh, libsh.sh]"
	current="$$(cat VERSION.txt | sed 's,\.,\\.,g')" \
		&& sed -i.bak "s,$${current},$(VERSION),g" \
			README.md install.sh libsh.sh \
		&& rm -f README.md.bak install.sh.bak libsh.sh.bak
	@echo "  - Setting version to '$(VERSION)' in VERSION.txt"
	echo "$(VERSION)" > VERSION.txt
	@echo "  - Preparing release commit"
	git add README.md VERSION.txt install.sh libsh.sh
	git commit --signoff --message "[release] Update version to $(VERSION)"
	@echo
	@echo "To complete the release for $(VERSION), run: \`make tag\`"
.PHONY: bump-version

tag: ## Create a new release Git tag
	@echo "--- $@"
	@version="$$(cat VERSION.txt)" && tag="v$$version" \
		&& git tag --annotate "$$tag" \
			--message "Release version $$version" \
		&& echo "Release tag '$$tag' created." \
		&& echo "To push: \`git push origin $$tag\`"
.PHONY: tag
