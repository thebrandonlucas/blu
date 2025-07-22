<script lang="ts">
	import quotes from '$lib/data/quotes.json';

	type Quote = {
		date: string;
		text: string;
		source: string;
	};

	let { quote, index }: { quote?: Quote; index?: number } = $props();

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

<span>{quote?.date}</span>
<blockquote>
	<span>{quote?.text}</span>
</blockquote>
<ul class="ml-12">
	<li>{quote?.source}</li>
</ul>
