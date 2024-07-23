// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  compatibilityDate: '2024-04-03',
  devtools: { enabled: true },
  modules: ["nuxt-quasar-ui","@nuxt-alt/proxy"],
  srcDir: "src",
  proxy: {
    https: false,
    proxies: {
      '/management': {
        target: process.env.API_URL,
        changeOrigin: true,
        headers: {Authorization: 'Bearer ' + process.env.API_KEY},

      }
    },
    cors: false
  },
  quasar: {
    config: {
      notify:{
        type: 'warning',
        position: 'center',
        timeout:0,
        multiLine: true,
        html:true,
        actions: [
          { label: 'OK', color: 'yellow', handler: () => { /* ... */ } }
        ]

      }
    },

    // iconSet: 'material-icons', // Quasar icon set
    // lang: 'en-US', // Quasar language pack

    // For special cases outside of where the auto-import strategy can have an impact
    // (like functional components as one of the examples),
    // you can manually specify Quasar components/directives to be available everywhere:
    //
    // components: [],
    // directives: [],

    // Quasar plugins
    plugins: [
      'Notify'
    ]
  }
})
