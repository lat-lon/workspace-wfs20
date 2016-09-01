package de.latlon.ogctestbed12.sql.converter;

import org.deegree.commons.tom.datetime.DateTime;
import org.deegree.commons.tom.datetime.Temporal;
import org.deegree.commons.tom.datetime.Time;
import org.deegree.commons.tom.primitive.BaseType;
import org.deegree.commons.tom.primitive.PrimitiveType;
import org.deegree.commons.tom.primitive.PrimitiveValue;
import org.deegree.feature.persistence.sql.SQLFeatureStore;
import org.deegree.feature.persistence.sql.converter.CustomParticleConverter;
import org.deegree.feature.persistence.sql.rules.Mapping;
import org.deegree.feature.persistence.sql.rules.PrimitiveMapping;

import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.util.Calendar;

import static org.deegree.commons.tom.datetime.ISO8601Converter.parseDateTime;
import static org.deegree.commons.tom.datetime.ISO8601Converter.parseTime;
import static org.deegree.commons.tom.primitive.BaseType.DATE_TIME;
import static org.deegree.commons.tom.primitive.BaseType.TIME;

/**
 * {@link CustomParticleConverter} for conversion between {@link PrimitiveValue}s (DateTime and Time) and SQL types with respect to the UTC Time.
 * Currently the UTC Time is only supported by the conversion from SQL value to {@link PrimitiveValue}
 *
 * @author <a href="mailto:goltz@lat-lon.de">Lyn Goltz</a>
 */
public class UtcTimeConverter implements CustomParticleConverter<PrimitiveValue> {

    private String column;

    private PrimitiveType type;

    @Override
    public void init( Mapping mapping, SQLFeatureStore fs ) {
        if ( !( mapping instanceof PrimitiveMapping ) )
            throw new IllegalArgumentException( "Only PrimitiveMappings are supported by the UtcTimeConverter." );
        PrimitiveMapping primitiveMapping = (PrimitiveMapping) mapping;
        checkType( primitiveMapping );
        column = primitiveMapping.getMapping().toString();
        type = primitiveMapping.getType();
    }

    @Override
    public String getSelectSnippet( String tableAlias ) {
        if ( tableAlias != null ) {
            if ( column.startsWith( "'" ) || column.contains( " " ) ) {
                return column.replace( "$0", tableAlias );
            }
            return tableAlias + "." + column;
        }
        return column;

    }

    @Override
    public String getSetSnippet( PrimitiveValue particle ) {
        return "?";
    }

    @Override
    public PrimitiveValue toParticle( ResultSet rs, int colIndex )
                            throws SQLException {
        Object sqlValue = rs.getObject( colIndex );
        if ( sqlValue == null ) {
            return null;
        }
        switch ( type.getBaseType() ) {
        case DATE_TIME:
            return toDateTimeParticle( sqlValue );
        case TIME:
            return toTimeParticle( sqlValue );
        default:
            throw new UnsupportedOperationException(
                                    "BaseType " + type.getBaseType() + " is not supported by the UtcTimeConverter." );
        }
    }

    @Override
    public void setParticle( PreparedStatement stmt, PrimitiveValue particle, int paramIndex )
                            throws SQLException {
        Object value = particle.getValue();
        if ( value != null ) {
            value = toSqlValue( value );
        }
        stmt.setObject( paramIndex, value );
    }

    private PrimitiveValue toDateTimeParticle( Object sqlValue ) {
        Temporal value = null;
        if ( sqlValue instanceof java.util.Date ) {
            Calendar cal = Calendar.getInstance();
            cal.setTime( (java.util.Date) sqlValue );
            value = new DateTime( cal, false );
        } else if ( sqlValue != null ) {
            throw new IllegalArgumentException( "Unable to convert SQL result value of type '" + sqlValue.getClass()
                                                + "' to DateTime particle." );
        }
        return new PrimitiveValue( value, type );
    }

    private PrimitiveValue toTimeParticle( Object sqlValue ) {
        Temporal value = null;
        if ( sqlValue instanceof java.util.Date ) {
            Calendar cal = Calendar.getInstance();
            cal.setTime( (java.util.Date) sqlValue );
            value = new Time( cal, false );
        } else if ( sqlValue != null ) {
            throw new IllegalArgumentException( "Unable to convert SQL result value of type '" + sqlValue.getClass()
                                                + "' to Time particle." );
        }
        return new PrimitiveValue( value, type );
    }

    private Object toSqlValue( Object input ) {
        switch ( type.getBaseType() ) {
        case DATE_TIME:
            return toSqlTimestamp( input );
        case TIME:
            return toSqlTime( input );
        default:
            throw new UnsupportedOperationException(
                                    "BaseType " + type.getBaseType() + " is not supported by the UtcTimeConverter." );
        }
    }

    /**
     * TODO handling of SQL timezone
     */
    private java.sql.Time toSqlTime( Object input ) {
        if ( input instanceof java.sql.Time ) {
            return (java.sql.Time) input;
        }
        if ( input instanceof java.util.Date ) {
            java.util.Date date = (java.util.Date) input;
            return new java.sql.Time( date.getTime() );
        } else if ( input instanceof Temporal ) {
            Temporal timeInstant = (Temporal) input;
            return new java.sql.Time( timeInstant.getTimeInMilliseconds() );
        } else {
            String s = input.toString();
            Time timeInstant = parseTime( s );
            return toSqlTime( timeInstant );
        }
    }

    /**
     * TODO handling of SQL timezone
     */
    private Timestamp toSqlTimestamp( Object input ) {
        if ( input instanceof Timestamp ) {
            return (Timestamp) input;
        }
        if ( input instanceof java.util.Date ) {
            java.util.Date date = (java.util.Date) input;
            return new Timestamp( date.getTime() );
        } else if ( input instanceof Temporal ) {
            Temporal timeInstant = (Temporal) input;
            return new Timestamp( timeInstant.getTimeInMilliseconds() );
        } else {
            String s = input.toString();
            if ( s.isEmpty() ) {
                return null;
            }
            DateTime timeInstant = parseDateTime( s );
            return toSqlTimestamp( timeInstant );
        }
    }

    private void checkType( PrimitiveMapping mapping ) {
        BaseType baseType = mapping.getType().getBaseType();
        if ( !DATE_TIME.equals( baseType ) && !TIME.equals( baseType ) )
            throw new UnsupportedOperationException(
                                    "BaseType " + baseType + " is not supported by the UtcTimeConverter." );
    }

}