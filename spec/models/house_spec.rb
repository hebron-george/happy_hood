require "rails_helper"

describe House do
  describe "attributes" do
    describe "address related fields" do
      it "has all the proper fields" do

        house = House.new(address: {
          street_address: "123 fake st",
          city: "Chicago",
          state: "IL",
          zip_code: "60601"
        })

        expect(house).to have_attributes(
          street_address: "123 fake st",
          city: "Chicago",
          state: "IL",
          zip_code: "60601"
        )
      end
    end

    describe "#zpid" do
      context "when no house_metadatum is available" do
        it "is nil" do
          house = House.new
          expect(house.zpid).to be_nil
        end
      end

      context "when a house_metadatum is available" do
        context "if the metadatum does not have a zpid" do
          it "is nil" do
            house = House.new
            house.house_metadatum = HouseMetadatum.new

            expect(house.zpid).to be_nil
          end
        end

        context "if the house metadatum has a zpid" do
          it "is the same as the house metadatum zpid" do
            house = House.new
            house.house_metadatum = HouseMetadatum.new(zpid: "1")

            expect(house.zpid).to eq("1")
          end
        end
      end
    end
  end

  describe "#valuation_on" do
    it "correctly returns a proper valuation" do
      date = Date.today
      house = House.new
      house.price_history[date.strftime(House::PRICE_HISTORY_DATE_FORMAT)] = 20

      expect(house.valuation_on(1.day.ago)).to eq(0)
      expect(house.valuation_on(date)).to eq(20)
    end
  end

  describe "#add_valuation" do
    it "is chainable" do
      date = 1.day.ago

      house = House.new
      house.add_valuation(date, 20)
      house.add_valuation(date, 10)
      house.add_valuation(date, 42)

      house2 = House.new
        .add_valuation(date, 20)
        .add_valuation(date, 10)
        .add_valuation(date, 42)

      expect(house.price_history).to eq(house2.price_history)
    end

    context "when there hasn't been a valuation" do
      it "creates a valuation" do
        house = House.new
        house.add_valuation(Date.today, 20)

        expect(house.valuation_on(Date.today)).to eq(20)
      end
    end

    context "when two updates happen on the same day" do
      it "keeps the last update" do
        date = Date.today

        house = House.new
          .add_valuation(date, 20)
          .add_valuation(date, 10)
          .add_valuation(date, 42)

        expect(house.valuation_on(date)).to eq(42)
      end
    end
  end

  describe "scopes" do
    describe "json scopes" do
      it "returns the correct houses" do
        House.new(address: { city: "Tampa", state: "FL", zip_code: "33635", street_address: "8110 Muddy Pines Pl" }).save(validate: false)

        results = House.with_street_address("8110 Muddy Pines Pl")
        expect(results).to be_a(ActiveRecord::Relation)
        expect(results.size).to eq(1)

        expect(results.first).to have_attributes(street_address: "8110 Muddy Pines Pl")
        expect(House.with_city("Tampa").first).to have_attributes(city: "Tampa")
        expect(House.with_state("FL").first).to have_attributes(state: "FL")
        expect(House.with_zip_code("33635").first).to have_attributes(zip_code: "33635")
        expect(House.with_address_attr(zip_code: "33635").first).to have_attributes(zip_code: "33635")
        expect(House.with_address_attr(city: "Chicago", zip_code: "33635")).to be_empty
      end
    end
  end
end
