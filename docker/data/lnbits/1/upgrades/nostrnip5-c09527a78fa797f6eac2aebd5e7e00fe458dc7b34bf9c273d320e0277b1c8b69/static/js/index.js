const mapDomain = function (obj) {
  obj.time = Quasar.date.formatDate(
    new Date(obj.time * 1000),
    'YYYY-MM-DD HH:mm'
  )

  return obj
}

window.app = Vue.createApp({
  el: '#vue',
  mixins: [window.windowMixin],
  data: function () {
    return {
      domains: [],
      addresses: [],
      domainRankingBraketOptions: [
        200, 500, 1000, 2000, 5000, 10000, 20000, 50000, 100000, 200000, 500000,
        1000000
      ],
      currencyOptions: [],
      domainsTable: {
        columns: [
          {name: 'id', align: 'left', label: 'ID', field: 'id'},
          {name: 'domain', align: 'left', label: 'Domain', field: 'domain'},
          {
            name: 'currency',
            align: 'left',
            label: 'Currency',
            field: 'currency'
          },
          {name: 'cost', align: 'left', label: 'Amount', field: 'cost'},
          {name: 'time', align: 'left', label: 'Created At', field: 'time'}
        ],
        pagination: {
          rowsPerPage: 10
        }
      },
      addressesTable: {
        columns: [
          {name: 'id', align: 'left', label: 'ID', field: 'id'},
          {
            name: 'active',
            align: 'left',
            label: 'Active',
            field: 'active',
            sortable: true
          },
          {
            name: 'local_part',
            align: 'left',
            label: 'Address',
            field: 'local_part',
            sortable: true
          },
          {
            name: 'pubkey',
            align: 'left',
            label: 'Pubkey',
            field: 'pubkey',
            sortable: true
          },
          {
            name: 'reimburse_amount',
            align: 'left',
            label: 'Reimburse',
            field: 'reimburse_amount',
            sortable: true
          },
          {
            name: 'time',
            align: 'left',
            label: 'Created At',
            field: 'time',
            sortable: true
          }
        ],
        pagination: {
          rowsPerPage: 10,
          page: 1,
          rowsNumber: 10
        }
      },
      formDialog: {
        show: false,
        data: {}
      },
      domainTab: null,
      addressFormDialog: {
        show: false,
        data: {}
      },
      rankingFormDialog: {
        show: false,
        data: {}
      },
      identifierFormDialog: {
        show: false,
        data: {}
      },
      settingsFormDialog: {
        show: false,
        data: {}
      },
      qrCodeDialog: {
        show: false,
        data: {}
      }
    }
  },
  methods: {
    resetFormDialog: function () {
      this.formDialog.show = false
      this.domainTab = 'charCount'
      this.formDialog.data = {
        cost_extra: {
          max_years: 1,
          char_count_cost: [],
          rank_cost: []
        }
      }
      this.addressFormDialog.show = false
      this.addressFormDialog.data = {
        relay: '',
        config: {
          relays: []
        },
        pubkey: '',
        local_part: ''
      }
      this.rankingFormDialog.show = false
      this.rankingFormDialog.data = {
        bucket: 0,
        identifiers: ''
      }
      this.identifierFormDialog.show = false
      this.identifierFormDialog.data = {
        searchText: '',
        bucket: 0,
        identifier: ''
      }
      this.settingsFormDialog.show = false
      this.qrCodeDialog.show = false
      this.qrCodeDialog.data = {
        payment_request: ''
      }
    },
    closeAddressFormDialog: function () {
      this.resetFormDialog()
    },
    closeFormDialog: function () {
      this.resetFormDialog()
    },
    getDomains: function () {
      var self = this

      LNbits.api
        .request(
          'GET',
          '/nostrnip5/api/v1/domains?all_wallets=true',
          this.g.user.wallets[0].inkey
        )
        .then(function (response) {
          self.domains = response.data.map(function (obj) {
            return mapDomain(obj)
          })
        })
    },

    getAddresses: function (props) {
      var self = this
      if (props) {
        self.addressesTable.pagination = props.pagination
      }
      let pagination = self.addressesTable.pagination
      const query = {
        all_wallets: true,
        limit: pagination.rowsPerPage,
        offset: (pagination.page - 1) * pagination.rowsPerPage ?? 0,
        sortby: pagination.sortBy || 'time',
        direction: pagination.descending ? 'desc' : 'asc'
      }
      const params = new URLSearchParams(query)

      LNbits.api
        .request(
          'GET',
          `/nostrnip5/api/v1/addresses/paginated?${params}`,
          this.g.user.wallets[0].inkey
        )
        .then(function (response) {
          const {data, total} = response.data
          self.addressesTable.pagination.rowsNumber = total
          self.addresses = data.map(function (obj) {
            return mapDomain(obj)
          })
        })
    },
    editAddress: function (address) {
      this.addressFormDialog.show = true
      this.addressFormDialog.data = address
    },
    addRelayForAddress: function (event) {
      event.preventDefault()
      this.removeRelayForAddress(this.addressFormDialog.data.relay)
      if (this.addressFormDialog.data.relay) {
        this.addressFormDialog.data.config.relays.push(
          this.addressFormDialog.data.relay
        )
      }
      this.addressFormDialog.data.relay = ''
    },
    removeRelayForAddress: function (relay) {
      this.addressFormDialog.data.config.relays = (
        this.addressFormDialog.data.config.relays || []
      ).filter(r => r !== relay)
    },
    saveDomain: function () {
      var data = this.formDialog.data
      var self = this
      const method = this.formDialog.data.id ? 'PUT' : 'POST'

      LNbits.api
        .request(
          method,
          '/nostrnip5/api/v1/domain',
          _.findWhere(this.g.user.wallets, {id: this.formDialog.data.wallet})
            .adminkey,
          data
        )
        .then(function (response) {
          self.domains = self.domains.filter(d => d.id !== response.data.id)
          self.domains.push(mapDomain(response.data))
          self.resetFormDialog()
        })
        .catch(function (error) {
          LNbits.utils.notifyApiError(error)
        })
    },

    deleteDomain: function (domain_id) {
      var self = this
      var domain = _.findWhere(this.domains, {id: domain_id})

      LNbits.utils
        .confirmDialog('Are you sure you want to delete this domain?')
        .onOk(function () {
          LNbits.api
            .request(
              'DELETE',
              '/nostrnip5/api/v1/domain/' + domain_id,
              _.findWhere(self.g.user.wallets, {id: domain.wallet}).adminkey
            )
            .then(function (response) {
              self.domains = self.domains.filter(d => d.id !== domain_id)
            })
            .catch(function (error) {
              LNbits.utils.notifyApiError(error)
            })
        })
    },
    saveAddress: function () {
      var self = this
      var formDialog = this.addressFormDialog
      if (formDialog.data.id) {
        this.updateAddress()
        return
      }
      var domain = _.findWhere(this.domains, {id: formDialog.data.domain_id})
      var adminkey = _.findWhere(self.g.user.wallets, {
        id: domain.wallet
      }).adminkey

      LNbits.api
        .request(
          'POST',
          '/nostrnip5/api/v1/domain/' + formDialog.data.domain_id + '/address',
          adminkey,
          formDialog.data
        )
        .then(function (response) {
          self.resetFormDialog()
          self.getAddresses()
        })
        .catch(function (error) {
          LNbits.utils.notifyApiError(error)
        })
    },
    updateAddress: function () {
      var self = this
      var data = this.addressFormDialog.data
      var domain = _.findWhere(this.domains, {id: data.domain_id})
      return LNbits.api
        .request(
          'PUT',
          '/nostrnip5/api/v1/domain/' + data.domain_id + '/address/' + data.id,
          _.findWhere(self.g.user.wallets, {id: domain.wallet}).adminkey,
          {
            pubkey: data.pubkey,
            relays: data.config.relays
          }
        )
        .then(function (response) {
          self.resetFormDialog()
          self.getAddresses()
        })
        .catch(function (error) {
          LNbits.utils.notifyApiError(error)
        })
    },
    deleteAddress: function (address_id) {
      var self = this
      var address = _.findWhere(this.addresses, {id: address_id})
      var domain = _.findWhere(this.domains, {id: address.domain_id})

      LNbits.utils
        .confirmDialog('Are you sure you want to delete this address?')
        .onOk(function () {
          LNbits.api
            .request(
              'DELETE',
              `/nostrnip5/api/v1/domain/${domain.id}/address/${address_id}`,
              _.findWhere(self.g.user.wallets, {id: domain.wallet}).adminkey
            )
            .then(function (response) {
              self.addresses = _.reject(self.addresses, function (obj) {
                return obj.id == address_id
              })
            })
            .catch(function (error) {
              LNbits.utils.notifyApiError(error)
            })
        })
    },
    activateAddress: function (domain_id, address_id) {
      var self = this
      var address = _.findWhere(this.addresses, {id: address_id})
      var domain = _.findWhere(this.domains, {id: address.domain_id})
      LNbits.utils
        .confirmDialog(
          'Are you sure you want to manually activate this address?'
        )
        .onOk(function () {
          return LNbits.api
            .request(
              'PUT',
              '/nostrnip5/api/v1/domain/' +
                domain_id +
                '/address/' +
                address_id +
                '/activate',
              _.findWhere(self.g.user.wallets, {id: domain.wallet}).adminkey
            )
            .then(function (response) {
              if (response.data.success) {
                self.$q.notify({
                  type: 'positive',
                  message: 'Address activated'
                })
              }
              self.getAddresses()
            })
            .catch(function (error) {
              LNbits.utils.notifyApiError(error)
            })
        })
    },
    showReimburseInvoice: function (address) {
      if (!address || address.reimburse_amount <= 0) {
        this.$q.notify({
          type: 'warning',
          message: 'Nothing to reimburse.'
        })
        return
      }
      var self = this
      self.$q.notify({
        type: 'positive',
        message: 'Generating reimbursement invoice.'
      })
      return LNbits.api
        .request(
          'GET',
          `/nostrnip5/api/v1/domain/${address.domain_id}` +
            `/address/${address.id}/reimburse`,
          self.g.user.wallets[0].adminkey
        )
        .then(function (response) {
          self.qrCodeDialog.show = true
          self.qrCodeDialog.data = response.data
        })
        .catch(function (error) {
          LNbits.utils.notifyApiError(error)
        })
    },
    refreshDomainRanking: function (braket) {
      var self = this
      return LNbits.api
        .request(
          'PUT',
          '/nostrnip5/api/v1/domain/ranking/' + braket,
          self.g.user.wallets[0].adminkey
        )
        .then(function (response) {
          self.$q.notify({
            type: 'positive',
            message: `Top ${braket} identifiers refreshed!`
          })
        })
        .catch(function (error) {
          LNbits.utils.notifyApiError(error)
        })
    },
    addDomainRanking: function () {
      var self = this
      return LNbits.api
        .request(
          'PATCH',
          '/nostrnip5/api/v1/domain/ranking/' +
            this.rankingFormDialog.data.bucket,
          self.g.user.wallets[0].adminkey,
          this.rankingFormDialog.data.identifiers
        )
        .then(function (response) {
          self.$q.notify({
            type: 'positive',
            message: 'Identifiers updated!'
          })
          self.resetFormDialog()
        })
        .catch(function (error) {
          LNbits.utils.notifyApiError(error)
        })
    },
    searchIdentifier: function () {
      var self = this
      return LNbits.api
        .request(
          'GET',
          '/nostrnip5/api/v1/ranking/search?q=' +
            this.identifierFormDialog.data.searchText,
          self.g.user.wallets[0].adminkey
        )
        .then(function (response) {
          self.identifierFormDialog.data.identifier = response.data
        })
        .catch(function (error) {
          LNbits.utils.notifyApiError(error)
        })
    },
    updateIdentifier: function () {
      var self = this
      return LNbits.api
        .request(
          'PUT',
          '/nostrnip5/api/v1/ranking',
          self.g.user.wallets[0].adminkey,
          {
            name: self.identifierFormDialog.data.identifier.name,
            rank: self.identifierFormDialog.data.identifier.rank
          }
        )
        .then(function (response) {
          self.$q.notify({
            type: 'positive',
            message: 'Identifier updated!'
          })
          self.resetFormDialog()
        })
        .catch(function (error) {
          LNbits.utils.notifyApiError(error)
        })
    },

    fetchSettings: function () {
      var self = this
      return LNbits.api
        .request(
          'GET',
          '/nostrnip5/api/v1/settings',
          self.g.user.wallets[0].adminkey
        )
        .then(function (response) {
          self.settingsFormDialog.data = response.data
        })
        .catch(function (error) {
          LNbits.utils.notifyApiError(error)
        })
    },
    updateSettings: function () {
      var self = this
      return LNbits.api
        .request(
          'PUT',
          '/nostrnip5/api/v1/settings',
          self.g.user.wallets[0].adminkey,
          self.settingsFormDialog.data
        )
        .then(function (response) {
          self.resetFormDialog()
          self.$q.notify({
            type: 'positive',
            message: 'Updated settings'
          })
        })
        .catch(function (error) {
          LNbits.utils.notifyApiError(error)
        })
    },

    domainNameFromId: function (domainId) {
      const domain = this.domains.find(d => d.id === domainId) || {}
      return domain.domain || ''
    },
    addressFullName: function (address) {
      if (!address) {
        return ''
      }
      const domain = this.domainNameFromId(address.domain_id)
      return `${address.local_part}@${domain}`
    },
    exportCSV: function () {
      LNbits.utils.exportCSV(this.domainsTable.columns, this.domains)
    },
    exportAddressesCSV: function () {
      LNbits.utils.exportCSV(this.addressesTable.columns, this.addresses)
    }
  },
  created() {
    this.resetFormDialog()
    if (this.g.user.wallets.length) {
      this.getDomains()
      this.getAddresses()
      this.fetchSettings()
    }
    LNbits.api
      .request('GET', '/api/v1/currencies')
      .then(response => {
        this.currencyOptions = ['sats', ...response.data]
      })
      .catch(LNbits.utils.notifyApiError)
  },
  computed: {
    domainOptions: function () {
      return this.domains.map(el => {
        return {
          label: el.domain,
          value: el.id
        }
      })
    },
    domainRankingAllOptions: function () {
      const rankings = this.domainRankingBraketOptions.map(r => ({
        value: r,
        label: `Top ${r} identifiers`
      }))
      return [{value: 0, label: 'Reserved'}].concat(rankings)
    }
  }
})
