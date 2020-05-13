BUMP_MODE ?= minor

release-bump-version: ## Set a new version for the project. (default: BUMP_MODE=minor
	@echo "--- $@"
	@echo "  - Bumping version $(BUMP_MODE)"
	versio bump file $(BUMP_MODE)
	@echo "  - Preparing release commit"
	git add README.md VERSION.txt install.sh libsh.sh
	git commit --signoff \
		--message "[release] Update version to $$(cat VERSION.txt)"
	@echo
	@echo "To complete the release for $(VERSION), run: \`make release-tag\`"
.PHONY: release-bump-version

release-tag: ## Create a new release Git tag
	@echo "--- $@"
	@version="$$(cat VERSION.txt)" && tag="v$$version" \
		&& git tag --annotate "$$tag" \
			--message "Release version $$version" \
		&& echo "Release tag '$$tag' created." \
		&& echo "To push: \`git push origin $$tag\`"
.PHONY: release-tag
