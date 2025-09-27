// @ts-check
import starlight from '@astrojs/starlight';
import { defineConfig } from 'astro/config';

// https://astro.build/config
export default defineConfig({
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
					label: 'Getting Started',
					items: [
						{ label: 'Overview', slug: 'overview' },
						{ label: 'Installation', slug: 'installation' },
						{ label: 'Quick Start', slug: 'quick-start' },
					],
				},
				{
					label: 'Core Package',
					items: [
						{ label: 'route_guards', slug: 'packages/route-guards' },
					],
				},
				{
					label: 'Framework Integrations',
					items: [
						{ label: 'go_router_guards', slug: 'packages/go-router-guards' },
					],
				},
				{
					label: 'Guides',
					items: [
						{ label: 'Creating Guards', slug: 'guides/creating-guards' },
						{ label: 'Type-Safe Routes', slug: 'guides/type-safe-routes' },
						{ label: 'Traditional Routes', slug: 'guides/traditional-routes' },
						{ label: 'Guard Combinations', slug: 'guides/guard-combinations' },
						{ label: 'Conditional Guards', slug: 'guides/conditional-guards' },
						{ label: 'Best Practices', slug: 'guides/best-practices' },
					],
				},
				{
					label: 'Examples',
					items: [
						{ label: 'Authentication', slug: 'examples/authentication' },
						{ label: 'Role-Based Access', slug: 'examples/role-based-access' },
						{ label: 'Permission Guards', slug: 'examples/permission-guards' },
						{ label: 'Multi-Layer Protection', slug: 'examples/multi-layer-protection' },
					],
				},
				{
					label: 'API Reference',
					autogenerate: { directory: 'reference' },
				},
			],
			customCss: [
				'./src/styles/custom.css',
				'@fontsource-variable/figtree',
			],
		}),
	],
});
