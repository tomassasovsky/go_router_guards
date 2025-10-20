// @ts-check
import starlight from '@astrojs/starlight';
import { defineConfig } from 'astro/config';
import tailwind from '@tailwindcss/vite';

// https://astro.build/config
export default defineConfig({
	site: 'https://guards.aquiles.dev',
	server: {
		allowedHosts: ['guards.aquiles.dev', 'home-astro.aquiles.dev'],
	},
	integrations: [
		starlight({
			title: 'Route Guards',
			description: 'Flexible and extensible guard system for navigation protection with framework integrations',
			logo: {
				src: './src/assets/icon.png',
				replacesTitle: false,
			},
			favicon: '/favicon.png',
			social: [
				{
					icon: 'github',
					label: 'GitHub',
					href: 'https://github.com/tomassasovsky/go_router_guards'
				}
			],
			sidebar: [
				{
					label: 'Tutorials',
					items: [
						{ label: 'Get Started', slug: 'tutorials/get-started' },
					],
				},
				{
					label: 'How‑to guides',
					items: [
						{ label: 'Router‑level guard', slug: 'how-to/router-level-guard' },
						{ label: 'Compose guards', slug: 'how-to/compose-guards' },
						{ label: 'Testing', slug: 'how-to/testing' },
					],
				},
				{
					label: 'Guides',
					items: [
						{ label: 'Migration Guide', slug: 'guides/migration' },
					],
				},
				{
					label: 'Reference',
					items: [
						{ label: 'API Reference', slug: 'reference/api-overview' },
						{ label: 'Naming Conventions', slug: 'reference/naming-conventions' },
					],
				},
				{
					label: 'Explanation',
					items: [
						{ label: 'Architecture', slug: 'explanation/architecture' },
						{ label: 'Why go_router_guards?', slug: 'explanation/why-go-router-guards' },
						{ label: 'Core Concepts', slug: 'explanation/core-concepts' },
					],
				},
			],
			customCss: [
				'./src/tailwind.css',
				'./src/styles/custom.css',
				'./src/styles/landing.css',
				'@fontsource-variable/figtree',
			],
		}),
	],
	vite: { plugins: [tailwind()] },
});
