window.app = Vue.createApp({
  el: '#vue',
  mixins: [window.windowMixin],
  data: function () {
    return {
      base_url: base_url,
      domain: domain,
      domain_id: domain_id,
      wallet: wallet,
      currency: currency,
      maxYears: maxYears,
      identifier: identifier,
      identifierCost: identifierCost,
      identifierAvailable: identifierAvailable,
      success: false,
      successData: {
        local_part: null,
        address_id: null
      },
      qrCodeDialog: {
        data: {
          payment_request: null
        },
        show: false
      },
      formDialog: {
        data: {
          local_part: identifier,
          years: 1,
          pubkey: ''
        }
      },
      urlDialog: {
        show: false
      }
    }
  },
  methods: {
    closeQrCodeDialog: function () {
      this.qrCodeDialog.show = false
    },
    checkIdentifier: function () {
      const urlParams = new URLSearchParams(window.location.search)

      urlParams.set('identifier', this.formDialog.data.local_part || '')
      window.location.search = urlParams
    },
    createAddress: function () {
      var self = this
      var qrCodeDialog = this.qrCodeDialog
      var formDialog = this.formDialog
      formDialog.data.domain_id = this.domain_id
      formDialog.data.create_invoice = true
      var localPart = formDialog.data.local_part

      axios
        .post(
          '/nostrnip5/api/v1/public/domain/' + this.domain_id + '/address',
          formDialog.data
        )
        .then(function (response) {
          qrCodeDialog.data = response.data
          qrCodeDialog.show = true

          qrCodeDialog.dismissMsg = self.$q.notify({
            timeout: 0,
            message: 'Waiting for payment...'
          })

          qrCodeDialog.paymentChecker = setInterval(function () {
            axios
              .get(
                '/nostrnip5/api/v1/domain/' +
                  self.domain_id +
                  '/payments/' +
                  response.data.payment_hash
              )
              .then(function (res) {
                if (res.data.paid) {
                  clearInterval(qrCodeDialog.paymentChecker)
                  qrCodeDialog.dismissMsg()
                  qrCodeDialog.show = false

                  self.successData.local_part = localPart
                  self.successData.address_id = qrCodeDialog.data.id
                  self.successData.rotation_secret =
                    qrCodeDialog.data.rotation_secret
                  self.success = true
                }
              })
          }, 3000)
        })
        .catch(LNbits.utils.notifyApiError)
    }
  }
})
