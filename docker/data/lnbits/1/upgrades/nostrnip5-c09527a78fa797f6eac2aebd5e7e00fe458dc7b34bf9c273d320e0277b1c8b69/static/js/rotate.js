window.app = Vue.createApp({
  el: '#vue',
  mixins: [window.windowMixin],
  data: function () {
    return {
      domain: domain,
      domain_id: domain_id,
      address_id: address_id,
      formDialog: {
        data: {
          pubkey: null,
          secret: secret
        }
      }
    }
  },
  methods: {
    updateAddress: function () {
      const formDialog = this.formDialog
      const newPubKey = this.formDialog.data.pubkey

      axios
        .put(
          '/nostrnip5/api/v1/domain/' +
            this.domain_id +
            '/address/' +
            this.address_id +
            '/rotate',
          formDialog.data
        )
        .then(() => {
          formDialog.data = {}
          Quasar.Notify.create({
            type: 'positive',
            message:
              'Success! Your pubkey has been updated. Please allow clients time to refresh the data.'
          })
        })
        .catch(LNbits.utils.notifyApiError)
    }
  }
})
