require 'test_helper'

class PaypalAdaptiveAccountTest < Test::Unit::TestCase
  def setup
    @gateway = PaypalAdaptiveAccountGateway.new(
                 :login => 'login',
                 :password => 'password'
               )

    @credit_card = credit_card
    @amount = 100
    
    @options = { 
      :order_id => '1',
      :billing_address => address,
      :description => 'Store Purchase'
    }
  end
  
  def test_supported_card_types
    assert_equal [:visa, :master, :american_express, :discover, :maestro, :solo, :carte_aurore, :carte_bleue, :cofinoga, :carte_aura, :tarjeta_aurora, :jcb, :etoiles], PaypalAdaptiveAccountGateway.supported_cardtypes
  end
  
  def test_supported_countries
   
  end  

  private
  
end
