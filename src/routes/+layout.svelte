<script lang="ts">
	import '../app.css';
	import Nav from '$lib/components/Nav.svelte';
	import BreadCrumbs from '$lib/components/BreadCrumbs.svelte';
	import { articles, blog, journal } from '$lib/store';
	import { getMdFiles } from '$lib/util';

	let { children } = $props();

	$articles = getMdFiles(import.meta.glob('../lib/md/articles/*.md', { eager: true })) || [];
	$blog = getMdFiles(import.meta.glob('../lib/md/blog/*.md', { eager: true })) || [];
	$journal = getMdFiles(import.meta.glob('../lib/md/journal/*.md', { eager: true })) || [];
</script>

<main class="prose prose-2xl mx-auto my-4 flex flex-col gap-12 p-4">
	<div class="flex flex-col items-center">
		<BreadCrumbs />
		<Nav />
	</div>
	<div>
		{@render children()}
	</div>
</main>
