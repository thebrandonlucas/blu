<script lang="ts">
	import quotes from '$lib/data/quotes.json';

	type Quote = {
		// This is the date _I_ discovered it, not the date it was written.
		// Therefore, it is not always desirable to show it.
		date: string;
		text: string;
		source: string;
		link?: string;
	};

	let {
		quote,
		index,
		showDate = false
	}: { quote?: Quote; index?: number; showDate?: boolean } = $props();

	let textArray = $state<string[]>([]);

	$effect(() => {
		if (!quote) {
			quote = index ? quotes[index] : getRandomQuote();
		}
		if (quote?.text.includes('\n')) {
			textArray = quote?.text.split('\n');
		}
	});

	function getRandomQuote(): Quote {
		const randomIndex = Math.floor(Math.random() * quotes.length);
		return quotes[randomIndex];
	}
</script>

{#if showDate}
	<span>{quote?.date}</span>
{/if}
<blockquote>
	{#if textArray?.length}
		{#each textArray as t}
			<div class="min-h-8">{t}</div>
		{/each}
	{:else}
		<span>{quote?.text}</span>
	{/if}
</blockquote>
<ul>
	{#if quote?.link}
		<a href={quote?.link}>
			<li>{quote?.source}</li>
		</a>
	{:else}
		<li>{quote?.source}</li>
	{/if}
</ul>
