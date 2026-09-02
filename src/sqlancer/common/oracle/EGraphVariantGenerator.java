package sqlancer.common.oracle;

import java.util.List;

public interface EGraphVariantGenerator {

    /**
     * Generates equivalent SQL variants for a given query string.
     *
     * @param query the original SQL query string
     * @return a list of SQL variants produced by the equivalence generator
     * @throws Exception if the external generator fails or the variants cannot be
     *                   produced
     */
    List<String> generateVariants(String query) throws Exception;

}
