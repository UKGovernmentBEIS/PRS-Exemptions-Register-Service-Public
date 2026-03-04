public with sharing class AddressDataProcessor {

    public class Root {
        public Header header;
        public List<Result> results;
    }

    public class Header {
        public String uri;
        public String query;
        public Integer offset;
        public Integer totalresults;
        public String format;
        public String dataset;
        public String lr;
        public Integer maxresults;
        public Integer matchprecision;
        public String epoch;
        public String lastupdate;
        public String output_srs;
    }

    public class Result {
        public DeliveryPointAddress DPA;
    }

    public static List<DeliveryPointAddress> processAddressData(String jsonInput) {
        Root data = (Root) JSON.deserialize(jsonInput, Root.class);
        List<DeliveryPointAddress> deliveryPointAddresses = new List<DeliveryPointAddress>();
        if(data.header.totalresults == 0) {
            return deliveryPointAddresses;
        }
        for (Result result :data.results) {
            deliveryPointAddresses.add(result.DPA);
        }
        deliveryPointAddresses.sort(new DPAComparator());

        return deliveryPointAddresses;
    }

    public static List<DeliveryPointAddress> processMatchData(String jsonInput) {
        Root data = (Root) JSON.deserialize(jsonInput, Root.class);
        List<DeliveryPointAddress> deliveryPointAddresses = new List<DeliveryPointAddress>();
        if(data.header.totalresults == 0 || data.results == null || data.results.isEmpty()) {
            return deliveryPointAddresses;
        }
        for (Result result :data.results) {
            deliveryPointAddresses.add(result.DPA);
        }
        deliveryPointAddresses.sort(new DPAMatchComparator());

        return deliveryPointAddresses;
    }

    private class DPAComparator implements Comparator<DeliveryPointAddress> {
        public Integer compare(DeliveryPointAddress dpa1, DeliveryPointAddress dpa2) {
            Integer returnValue = 0;
        
            if(dpa1 == null && dpa2 == null) {
                returnValue = 0;
            } else if(dpa1 == null) {
                returnValue = -1; 
            } else if(dpa2 == null) {
                returnValue = 1;
            } else if (dpa1.UPRN == null && dpa2.UPRN == null) {
                returnValue = 0;
            } else if (dpa1.UPRN == null) {
                returnValue = -1;
            } else if (dpa2.UPRN == null) {
                returnValue = 1;
            } else if (dpa1.UPRN < dpa2.UPRN) {
                returnValue = -1;
            } else if (dpa1.UPRN > dpa2.UPRN) {
                returnValue = 1;
            }
            return returnValue;
        }
    }

    private class DPAMatchComparator implements Comparator<DeliveryPointAddress> {
        public Integer compare(DeliveryPointAddress dpa1, DeliveryPointAddress dpa2) {
            Integer returnValue = 0;
        
            if(dpa1 == null && dpa2 == null) {
                returnValue = 0;
            } else if(dpa1 == null) {
                returnValue = 1;
            } else if(dpa2 == null) {
                returnValue = -1;
            } else if (dpa1.MATCH == null && dpa2.MATCH == null) {
                returnValue = 0;
            } else if (dpa1.MATCH == null) {
                returnValue = 1;
            } else if (dpa2.MATCH == null) {
                returnValue = -1;
            } else if (dpa1.MATCH < dpa2.MATCH) {
                returnValue = 1;
            } else if (dpa1.MATCH > dpa2.MATCH) {
                returnValue = -1;
            }
            return returnValue;
        }
    }
}