window.app = Vue.createApp({
  el: '#vue',
  mixins: [window.windowMixin],
  data: function () {
    return {
      domainRankingBraketOptions: [
        200, 500, 1000, 2000, 5000, 10000, 20000, 50000, 100000, 200000, 500000,
        1000000
      ],
      currencyOptions: [],
      domainForm: {
        show: false,
        data: domain
      },
      domainTab: 'charCount'
    }
  },
  methods: {
    resetFormDialog: function () {
      this.domainForm.show = false
      this.domainTab = 'charCount'
    },
    saveDomain: async function () {
      try {
        await LNbits.api.request(
          'PUT',
          '/nostrnip5/api/v1/domain',
          _.findWhere(this.g.user.wallets, {id: this.domainForm.data.wallet})
            .adminkey,
          this.domainForm.data
        )
        this.$q.notify({
          type: 'positive',
          message: 'Domain updated!'
        })
      } catch (error) {
        this.$q.notify({
          type: 'negative',
          message: 'Failed to update!'
        })
        LNbits.utils.notifyApiError(error)
      }
    },
    addCharCountCost: function () {
      this.domainForm.data.cost_extra.char_count_cost.push({
        bracket: 0,
        amount: 1
      })
    },
    removeCharCountCost: function (index) {
      if (index < this.domainForm.data.cost_extra.char_count_cost.length) {
        this.domainForm.data.cost_extra.char_count_cost.splice(index, 1)
      }
    },
    addRankCost: function () {
      this.domainForm.data.cost_extra.rank_cost.push({
        bracket: 0,
        amount: 1
      })
    },
    removeRankCost: function (index) {
      if (index < this.domainForm.data.cost_extra.rank_cost.length) {
        this.domainForm.data.cost_extra.rank_cost.splice(index, 1)
      }
    },
    addPromotion: function () {
      this.domainForm.data.cost_extra.promotions.push({
        code: '',
        buyer_discount_percent: 0,
        referer_bonus_percent: 0
      })
    },
    removePromotion: function (index) {
      if (index < this.domainForm.data.cost_extra.promotions.length) {
        this.domainForm.data.cost_extra.promotions.splice(index, 1)
      }
    }
  },
  created() {
    this.resetFormDialog()
  }
})
