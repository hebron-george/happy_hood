require "rails_helper"

describe ZpidCollector do
  describe "#get_zpid" do
    let(:house) do
      metadatum = HouseMetadatum.new
      House.new(house_metadatum: metadatum,
                address: {
                  city: "Salt Lake City",
                  state: "UT",
                  zip_code: "84044",
                  street_address: "123 Fake St"
                })
    end

    context "when zillow does not have data for the house" do
      it "raises an appropriate error" do
        mock_response = instance_double(Rubillow::Models::SearchResult,
                                        success?: false,
                                        message: "House was obliterated three years ago")

        allow(Rubillow::HomeValuation).to receive(:search_results).and_return(mock_response)

        instance = described_class.new(house)

        expect { instance.get_zpid }.to raise_error(
          ZpidCollectorError,
          a_string_including(
            "Could not update zpid for House",
            "House was obliterated"
          )
        )
      end
    end

    context "when zillow has the data for the house" do
      context "and the data does not include a zpid" do
        it "does not update the zpid" do
          mock_response = instance_double(Rubillow::Models::SearchResult,
                                          success?: true,
                                          zpid: nil)

          allow(Rubillow::HomeValuation).to receive(:search_results).and_return(mock_response)

          instance = described_class.new(house)

          expect { instance.get_zpid }.not_to change { house.zpid }
        end
      end

      context "and the data has a zpid" do
        it "updates the zpid" do
          mock_response = instance_double(Rubillow::Models::SearchResult,
                                          success?: true,
                                          zpid: "my-zpid-from-zillow")

          allow(Rubillow::HomeValuation).to receive(:search_results).and_return(mock_response)

          instance = described_class.new(house)

          expect { instance.get_zpid }.to change { house.zpid }.from(nil).to("my-zpid-from-zillow")
        end
      end
    end
  end

  describe ".fill_missing_zpids" do
    context "when there are no houses to update" do
      it "returns a result with a count" do
        result = described_class.fill_missing_zpids

        expect(result)
          .to be_a(
            ZpidCollectorResult
          ).and have_attributes(
            updated_count: 0,
            total_houses: 0
          )
      end
    end

    context "when only some houses to update" do
      let(:hood) { Hood.create }

      context "when they all update" do
        it "updates all the zpids" do
          house1 = hood.houses.create(
            address: { street_address: "123" },
            house_metadatum: HouseMetadatum.new
          )
          house2 = hood.houses.create(
            address: { street_address: "abc" },
            house_metadatum: HouseMetadatum.new
          )

          mock_response = instance_double(Rubillow::Models::SearchResult,
                                          success?: true,
                                          zpid: "my-zpid-from-zillow")

          allow(Rubillow::HomeValuation).to receive(:search_results).and_return(mock_response)

          result = described_class.fill_missing_zpids

          expect(result).to have_attributes(updated_count: 2, total_houses: 2)

          expect(house1.reload.zpid).to eq("my-zpid-from-zillow")
          expect(house2.reload.zpid).to eq("my-zpid-from-zillow")
        end
      end

      context "when one of the houses to update fails" do
        it "updates the other house's zpid" do
          house1 = hood.houses.create(
            address: { street_address: "123" },
            house_metadatum: HouseMetadatum.new
          )
          house2 = hood.houses.create(
            address: { street_address: "abc" },
            house_metadatum: HouseMetadatum.new
          )

          mock_success_response = instance_double(Rubillow::Models::SearchResult,
                                                  success?: true,
                                                  zpid: "my-zpid-from-zillow")
          mock_failure_response = instance_double(Rubillow::Models::SearchResult,
                                                  success?: false,
                                                  message: "house is a trashbin")

          allow(Rubillow::HomeValuation).to receive(:search_results)
            .with(hash_including(address: house1.street_address))
            .and_return(mock_success_response)
          allow(Rubillow::HomeValuation).to receive(:search_results)
            .with(hash_including(address: house2.street_address))
            .and_return(mock_failure_response)

          result = described_class.fill_missing_zpids

          expect(result).to have_attributes(updated_count: 1, total_houses: 2)

          expect(house1.reload.zpid).to eq("my-zpid-from-zillow")
          expect(house2.reload.zpid).to be_nil
        end
      end
    end
  end
end
