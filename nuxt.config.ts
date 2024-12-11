// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  compatibilityDate: '2024-04-03',
  devtools: { enabled: true },
  modules: ["nuxt-quasar-ui","@nuxt-alt/proxy"],
  srcDir: "src",
  proxy: {
    https: false,
    proxies: {
      '/management/passwd': {
        target: process.env.API_URL,
        changeOrigin: true,
        changeHost: true,
        headers: {Authorization: 'Bearer ' + process.env.API_KEY},
        secure: false,
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

      },
      brand: {
        primary: process.env.COLOR_PRIMARY || '#1976d2',
        secondary: process.env.COLOR_SECONDARY || '#26A69A',
        accent: process.env.COLOR_ACCENT || '#9C27B0',

        dark: process.env.COLOR_DARK || '#1d1d1d',
        'dark-page': process.env.COLOR_DARK_PAGE ||'#121212',

        positive: process.env.COLOR_POSITIVE || '#21BA45',
        negative: process.env.COLOR_NEGATIVE || '#C10015',
        info: process.env.COLOR_INFO || '#31CCEC',
        warning: process.env.COLOR_WARNING ||'#F2C037'
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
