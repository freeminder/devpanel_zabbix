class WebsitesController < ApplicationController
  require 'open-uri'
  require 'uri/http'
  require 'addressable/uri'
  require 'public_suffix'

  before_filter :grab_data, only: [:index, :new]


  def grab_data
    # generate array with http tests
    @httptests = ZBX.query(
      "method": "httptest.get",
      "params": {
        "output": "extend",
        "selectSteps": "extend",
      }
    )

    # generate array with hosts
    @hosts = ZBX.query(
        method: "host.get",
        params: {
          "output": "extend",
        }
    )
  end


  def index
  end

  def new
  end

  # def show
  #   # extract site domain from URL
  #   uri = URI.parse()
  #   domain = PublicSuffix.parse(uri.host)
  #   site_domain = domain.domain
  #   body = open("#{ENV['SUCURI_API']}#{site_domain}").read
  # end

  def create
    if ZBX.query(
      "method": "httptest.create",
      "params": {
        "name": params[:url],
        "hostid": params[:hostid],
        "steps": [
          {
            "name": params[:url],
            "url": params[:url],
            "status_codes": 200,
            "no": 1
          },
        ]
      },
    )['httptestids']
      # show success popup
      flash[:notice] = "HTTP test has been successfully added!"
      redirect_to controller: 'websites', action: 'index'
    else
      render 'new'
    end
  end

  def update
    if ZBX.query(
      "method": "httptest.update",
      "params": {
        # "name": params[:url],
        "httptestid": params[:id],
        "status": params[:status],
        # "steps": [
        #   {
        #     "name": params[:url],
        #     "url": params[:url],
        #     "status_codes": 200,
        #     "no": 1
        #   },
        # ]
      },
    )['httptestids']
      # show success popup
      flash[:notice] = "HTTP test has been successfully updated!"
      redirect_to controller: 'websites', action: 'index'
    else
      render 'new'
    end
  end

  def destroy
    if params[:id] == params[:id].to_i.to_s
      ZBX.query(
        "method": "httptest.delete",
        "params": [
          params[:id]
        ]
      )

      # show success popup
      respond_to do |format|
        format.any { redirect_to action: 'index' }
        flash[:notice] = 'HTTP test has been successfully removed!'
      end
    else
      # show error popup
      respond_to do |format|
        format.any { redirect_to action: 'show' }
        flash[:error] = 'Wrong HTTP test id!'
      end
    end
  end

end
