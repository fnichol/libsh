BUMP_MODE ?=
BUMP_PRE ?=
BUMP_SET ?=

ifndef NAME
$(error NAME is not set in Makefile and is required in release.mk)
endif

ifndef REPO
$(error REPO is not set in Makefile and is required in release.mk)
endif

release-prepare: clean prepush release-bump-version release-update-changelog \
		release-create-branch release-create-release-commit \
		release-tag release-bump-version-dev release-create-dev-commit \
		release-push-head
	@echo "--- $@"
	@echo "Final release steps:"
	@echo ""
	@echo "1. Create a pull request for the release branch by visiting:"
	@echo "       $(REPO)/pull/new/release-$$(cat tmp/LAST_VERSION.txt)"
	@echo "2. Wait for CI to turn green"
	@echo "3. Comment on the pull request with \`bors merge\`"
	@echo "4. Wait for bors to integrate, test, and merge the pull request"
	@echo "5. Locally run \`git push origin v$$(cat tmp/LAST_VERSION.txt)\`"
	@echo ""
.PHONY: release-prepare

release-bump-version: ## Set a new version for the project.
	@echo "--- $@"
	@echo "  - Bumping version"
	@mkdir -p tmp
	@cp VERSION.txt tmp/LAST_VERSION.txt
	@if [ -n "$(BUMP_SET)" ]; then \
		echo "$(BUMP_SET)" >VERSION.txt; \
	elif [ -n "$(BUMP_MODE)" ] && [ -n "$(BUMP_PRE)" ]; then \
		versio bump file $(BUMP_MODE) --pre-release $(BUMP_PRE); \
	elif [ -n "$(BUMP_MODE)" ]; then \
		versio bump file $(BUMP_MODE); \
	else \
		versio bump file set --no-pre-release; \
	fi
	@echo "    VERSION.txt now set to: $$(cat VERSION.txt)"
.PHONY: release-bump-version

release-bump-version-dev:
	@echo "--- $@"
	@echo "  - Bumping version for next iteration"
	@mkdir -p tmp
	@cp VERSION.txt tmp/LAST_VERSION.txt
	@if grep -q -E '^\d+\.\d+.\d+-.+' tmp/LAST_VERSION.txt; then \
		versio bump file set --pre-release dev; \
	else \
		versio bump file minor --pre-release dev; \
	fi
	@echo "    VERSION.txt now set to: $$(cat VERSION.txt)"
.PHONY: release-bump-version-dev

release-create-branch:
	@echo "--- $@"
	git checkout -b "release-$$(cat VERSION.txt)"
.PHONY: release-create-branch

release-create-dev-commit:
	@echo "--- $@"
	git add .
	git commit --signoff \
		--message "chore: start next iteration $$(cat VERSION.txt)"
.PHONY: release-create-dev-commit

release-create-release-commit:
	@echo "--- $@"
	git add .
	git commit --signoff \
		--message "release: $(NAME) $$(cat VERSION.txt)"
.PHONY: release-create-release-commit

release-push-head:
	@echo "--- $@"
	git push origin HEAD
.PHONY: release-push-head

release-tag: ## Create a new release Git tag
	@echo "--- $@"
	version="$$(cat VERSION.txt)" && git tag \
		--annotate "v$$version" --message "release: $(NAME) $$version"
.PHONY: release-tag

release-update-changelog:
	@echo "--- $@"
	version="$$(cat VERSION.txt)" && tag_name="v$$version" \
		&& ./.ci/update-changelog.sh "$(REPO)" "$$version" "$$tag_name"
.PHONY: release-update-changelog
