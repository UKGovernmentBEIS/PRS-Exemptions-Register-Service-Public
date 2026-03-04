@isTest
public class MockProvider implements System.StubProvider {

    public Boolean showLogs = false;
    private class Invocation {
        String methodName;
        List<Object> params;

        Invocation(String methodName, List<Object> params) {
            this.methodName = methodName;
            this.params = (params == null) ? new List<Object>(0) : new List<Object>(params);
        }

        public Boolean equals(Object obj) {
        if (obj instanceof Invocation) {
            Invocation other = (Invocation) obj;
            if (this.methodName != other.methodName) {
                return false;
            }
            if (this.params.size() != other.params.size()) {
                return false;
            }
            for (Integer i = 0; i < this.params.size(); i++) {
                Object p1 = this.params[i];
                Object p2 = other.params[i];
                
                if (p1 instanceof Map<String, Object> && p2 instanceof Map<String, Object>) {
                    if (!mapsEqual((Map<String, Object>)p1, (Map<String, Object>)p2)) {
                        return false;
                    }
                    continue;
                }
                
                if (p1 != p2) {
                    return false;
                }
            }
            return true;
        }
        return false;
    }

    private Boolean mapsEqual(Map<String, Object> map1, Map<String, Object> map2) {
        if (map1.size() != map2.size()) {
            return false;
        }
        for (String key : map1.keySet()) {
            if (!map2.containsKey(key) || map1.get(key) != map2.get(key)) {
                return false;
            }
        }
        return true;
    }


        public Integer hashCode() {
            return (methodName + ':' + String.valueOf(params)).hashCode();
        }
    }

    private Map<Invocation, Object> stubs = new Map<Invocation, Object>();
    private Invocation lastInvocation;

    public class StubOngoing {
        private MockProvider provider;
        private Object mock;

        StubOngoing(MockProvider provider, Object mock) {
            this.provider = provider;
            this.mock = mock;
        }

        public Object thenReturn(Object value) {
            if (provider.lastInvocation == null) {
                throw new Exceptions.MockException('No method invocation captured. Call a method on the mock first.');
            }
            provider.stubs.put(provider.lastInvocation, value);
            provider.lastInvocation = null;
            return mock;
        }

        public Object thenThrow(Exception e) {
            if (provider.lastInvocation == null) {
                throw new Exceptions.MockException('No method invocation captured. Call a method on the mock first.');
            }
            provider.stubs.put(provider.lastInvocation, e);
            provider.lastInvocation = null;
            return mock;
        }
    }

    public StubOngoing when(Object mock) {
        return new StubOngoing(this, mock);
    }

    public Object handleMethodCall(
        Object stubbedObject,
        String stubbedMethodName,
        Type returnType,
        List<Type> parameterTypes,
        List<String> parameterNames,
        List<Object> parameters
    ) {
        if(showLogs) {
            System.debug('=== handleMethodCall START ===');
            System.debug('Method called: ' + stubbedMethodName);
            System.debug('Parameters passed: ' + parameters);
            System.debug('Total stubs registered: ' + stubs.size());
        }
        
        
        lastInvocation = new Invocation(stubbedMethodName, parameters);

        if(showLogs) {
            System.debug('Created invocation hashCode: ' + lastInvocation.hashCode());
            System.debug('Checking stubs.containsKey: ' + stubs.containsKey(lastInvocation));

            for (Invocation stubInv : stubs.keySet()) {
                // Debug all registered stubs
                System.debug('--- Registered Stub ---');
                System.debug('  Method: ' + stubInv.methodName);
                System.debug('  Params: ' + stubInv.params);
                System.debug('  HashCode: ' + stubInv.hashCode());
                System.debug('  Equals current? ' + stubInv.equals(lastInvocation));
                System.debug('  Return value: ' + stubs.get(stubInv));
            }
        }
        
        if (stubs.containsKey(lastInvocation)) {
            Object value = stubs.get(lastInvocation);
            if(showLogs) { 
                System.debug('MATCH FOUND! Returning: ' + value);
            }

            if (value instanceof Exception) {
                throw (Exception) value;
            }

            if (value == null) {
                return null;
            }

            if (returnType == Integer.class) {
                return (Integer) value;
            }
            if (returnType == Boolean.class) {
                return (Boolean) value;
            }
            if (returnType == Decimal.class) {
                return (Decimal) value;
            }
            if (returnType == Double.class) {
                return (Double) value;
            }
            if (returnType == Long.class) {
                return (Long) value;
            }
            if (returnType == String.class) {
                return String.valueOf(value);
            }

            return value;
        }

        if(showLogs) {  
            System.debug('NO MATCH - returning null');
        }
        
        return null;
    }


    public Object createMock(Type classToMock) {
        return Test.createStub(classToMock, this);
    }
}
