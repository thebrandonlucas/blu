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
	}: { quote?: Quote; index?: number; showDate: boolean } = $props();

	$effect(() => {
		if (!quote) {
			quote = index ? quotes[index] : getRandomQuote();
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
	<span>{quote?.text}</span>
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
