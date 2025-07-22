<script lang="ts">
	import quotes from '$lib/data/quotes.json';
	import Quote from './Quote.svelte';
</script>

{#each quotes as quote}
	<Quote showDate {quote} />
	<hr />
{/each}
