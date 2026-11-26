
.PHONY: all lint kubeconform kubeval test package debug debug-ui

all: lint kubeconform test package

# Kubernetes versions the rendered manifests are validated against.
# Schemas come from https://github.com/yannh/kubernetes-json-schema (kubeconform's default source).
KUBERNETES_VERSIONS ?= 1.34.0 1.35.0 1.36.0 1.37.0
KUBECONFORM_FLAGS ?= -strict -ignore-missing-schemas -summary

lint:
	helm lint charts/onechart/
	helm lint charts/cron-job/
	helm lint charts/static-site

kubeconform:
	@set -e; for chart in onechart cron-job static-site; do \
		rm -rf manifests; \
		mkdir manifests; \
		echo "helm template charts/$$chart --output-dir manifests"; \
		helm template charts/$$chart --output-dir manifests; \
		for version in $(KUBERNETES_VERSIONS); do \
			echo "kubeconform $(KUBECONFORM_FLAGS) -kubernetes-version $$version manifests/"; \
			kubeconform $(KUBECONFORM_FLAGS) -kubernetes-version $$version manifests/; \
		done; \
	done

# Kept for backwards compatibility: kubeval was replaced by kubeconform.
kubeval: kubeconform

test:
	helm dependency update charts/onechart
	helm unittest charts/onechart

	helm dependency update charts/cron-job
	helm unittest charts/cron-job

	helm dependency update charts/static-site
	helm unittest charts/static-site

package:
	helm dependency update charts/onechart
	helm package charts/onechart
	mv onechart*.tgz docs

	helm dependency update charts/cron-job
	helm package charts/cron-job
	mv cron-job*.tgz docs

	helm dependency update charts/static-site
	helm package charts/static-site
	mv static-site*.tgz docs

	helm repo index docs --url https://chart.onechart.dev

debug:
	helm dependency update charts/onechart
	helm template my-release charts/onechart/ -f values.yaml --debug

debug-cron-job:
	helm dependency update charts/cron-job
	helm template charts/cron-job/ -f values-cron-job.yaml --debug
