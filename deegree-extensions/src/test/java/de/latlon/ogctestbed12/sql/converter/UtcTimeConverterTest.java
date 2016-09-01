package de.latlon.ogctestbed12.sql.converter;

import org.deegree.commons.tom.primitive.BaseType;
import org.deegree.commons.tom.primitive.PrimitiveType;
import org.deegree.commons.tom.primitive.PrimitiveValue;
import org.deegree.feature.persistence.sql.rules.Mapping;
import org.deegree.feature.persistence.sql.rules.PrimitiveMapping;
import org.deegree.sqldialect.filter.MappingExpression;
import org.junit.Test;
import org.mockito.Mockito;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Date;

import static org.deegree.commons.tom.primitive.BaseType.*;
import static org.hamcrest.CoreMatchers.is;
import static org.junit.Assert.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

/**
 * @author <a href="mailto:goltz@lat-lon.de">Lyn Goltz</a>
 */
public class UtcTimeConverterTest {

    @Test
    public void testToParticle_time()
                            throws Exception {
        UtcTimeConverter utcTimeConverter = new UtcTimeConverter();
        utcTimeConverter.init( mapping( TIME ), null );

        PrimitiveValue particleValue = utcTimeConverter.toParticle(
                                resultSet(), 1 );

        String particleValueAsText = particleValue.getAsText();
        assertThat( particleValueAsText.matches( "\\d{2}:\\d{2}:\\d{2}.\\d{3}\\+\\d{2}:\\d{2}" ), is( true ) );
    }

    @Test
    public void testToParticle_dateTime()
                            throws Exception {
        UtcTimeConverter utcTimeConverter = new UtcTimeConverter();
        utcTimeConverter.init( mapping( DATE_TIME ), null );

        PrimitiveValue particleValue = utcTimeConverter.toParticle(
                                resultSet(), 1 );

        String particleValueAsText = particleValue.getAsText();
        assertThat( particleValueAsText.matches( "\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}.\\d{3}\\+\\d{2}:\\d{2}" ),
                    is( true ) );
    }

    @Test(expected = Exception.class)
    public void testInit_date()
                            throws Exception {
        UtcTimeConverter utcTimeConverter = new UtcTimeConverter();
        utcTimeConverter.init( mapping( DATE ), null );
    }

    private Mapping mapping( BaseType baseType ) {
        PrimitiveMapping primitiveMapping = mock( PrimitiveMapping.class );
        when( primitiveMapping.getType() ).thenReturn( new PrimitiveType( baseType ) );
        MappingExpression mapping = mock( MappingExpression.class );
        when( mapping.toString() ).thenReturn( "column" );
        when( primitiveMapping.getMapping() ).thenReturn( mapping );
        return primitiveMapping;
    }

    private ResultSet resultSet()
                            throws SQLException {
        ResultSet resultSet = mock( ResultSet.class );
        when( resultSet.getObject( Mockito.anyInt() ) ).thenReturn( new Date() );
        return resultSet;
    }

}