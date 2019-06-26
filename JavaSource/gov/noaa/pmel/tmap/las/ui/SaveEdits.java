package gov.noaa.pmel.tmap.las.ui;

import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;
import java.util.Map.Entry;
import java.util.TimeZone;

import javax.xml.bind.DatatypeConverter;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.google.gson.JsonArray;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import com.google.gson.JsonStreamParser;

import gov.noaa.pmel.tmap.las.product.server.LASAction;

public class SaveEdits extends LASAction {

	private static final long serialVersionUID = -3128795801022648379L;

	private static Logger log = LoggerFactory.getLogger(SaveEdits.class.getName());

	private static String ERROR = "error";
	private static String EDITS = "edits";

	private boolean configured;

	/**
	 * Initialization if setting of WOCE flags is to be supported
	 */
	public SaveEdits() {
		super();
		log.debug("Initializing SaveEdits");
		configured = false;

		// TODO: configure and set configured to true (or remove/replace it)

	}

	@Override
	public String execute() throws Exception {
		// Make sure this is configured for setting WOCE flags
		if ( ! configured ) {
			logerror(request, "LAS not configured to allow editing of WOCE flags", "Illegal action");
			return ERROR;
		}

		// Parser to convert Ferret date strings into Date objects
		SimpleDateFormat fullDateParser = new SimpleDateFormat("dd-MMM-yyyy HH:mm:ss");
		fullDateParser.setTimeZone(TimeZone.getTimeZone("UTC"));

		// Get the username of the reviewer assigning these WOCE flags
		String username;
		try {
			log.debug("Assigning SaveEdits username");
			username = request.getUserPrincipal().getName();
		} catch ( Exception ex ) {
			logerror(request, "Unable to get the username for WOCE flagging", ex);
			return ERROR;
		}
		if ( (username == null) || username.isEmpty() ) {
			logerror(request, "No username for WOCE flagging", "");
			return ERROR;
		}

		JsonStreamParser parser = new JsonStreamParser(request.getReader());
		JsonObject message = (JsonObject) parser.next();

		// LAS temporary DSG file to update
		String tempname;
		try {
			tempname = message.get("temp_file").getAsString();
		} catch ( Exception ex ) {
			logerror(request, "Unable to get temp_file for WOCE flagging", ex);
			return ERROR;
		}
		if ( (tempname == null) || tempname.isEmpty() ) {
			logerror(request, "No temp_file for WOCE flagging", "");
			return ERROR;
		}

		// WOCE flag comment
		String comment;
		try {
			String encodedComment = message.get("comment").getAsString();
			comment = new String(DatatypeConverter.parseHexBinary(encodedComment), "UTF-16");
		} catch ( Exception ex ) {
			logerror(request, "Unable to get the comment for WOCE flagging", ex);
			return ERROR;
		}
		if ( comment.isEmpty() ) {
			logerror(request, "No comment given in the WOCE flags", "");
			return ERROR;
		}

		// List of data points getting the WOCE flag
		JsonArray edits;
		try {
			edits = (JsonArray) message.get("edits");
			if ( edits.size() < 1 )
				throw new IllegalArgumentException("No edits given");
		} catch ( Exception ex ) {
			logerror(request, "Unable to get the edits for WOCE flagging", ex);
			return ERROR;
		}

		// Create the list of data locations for the WOCE event
		String expocode = null;
		Character woceFlag = null;
		String woceName = null;
		String dataName = null;
		try {
			for ( JsonElement rowValues : edits ) {
				for ( Entry<String,JsonElement> rowEntry : ((JsonObject) rowValues).entrySet() ) {
					Date dataDate = null;
					Double longitude = null;
					Double latitude = null;
					Double dataValue = null;
					// Neither the name nor the value should be null.
					// Because of going through Ferret, everything will be uppercase
					// but just to be sure....
					String name = rowEntry.getKey().trim().toUpperCase(Locale.ENGLISH);
					String value = rowEntry.getValue().getAsString().trim().toUpperCase(Locale.ENGLISH);
					if ( name.equals("EXPOCODE") || name.equals("EXPOCODE_") ) {
						if ( expocode == null )
							expocode = value;
						else if ( ! expocode.equals(value) )
							throw new IllegalArgumentException("Mismatch of expocodes; " +
									"previous: '" + expocode + "'; current: '" + value + "'");
					}
					else if ( name.equals("DATE") ) {
						dataDate = fullDateParser.parse(value);
					}
					else if ( name.equals("LONGITUDE") ) {
						longitude = Double.parseDouble(value);
					}
					else if ( name.equals("LATITUDE") ) {
						latitude = Double.parseDouble(value);
					}
					else if ( name.startsWith("WOCE_") ) {
						// Name and value of the WOCE flag to assign
						if ( woceName == null )
							woceName = name;
						else if ( ! woceName.equals(name) )
							throw new IllegalArgumentException("Mismatch of WOCE names; " + 
									"previous: '" + woceName + "'; current: '" + name + "'");
						if ( value.length() != 1 )
							throw new IllegalArgumentException("Invalid WOCE flag value '" + value + "'");
						Character givenFlag = value.charAt(0);
						if ( woceFlag == null )
							woceFlag = givenFlag;
						else if ( ! woceFlag.equals(givenFlag) )
							throw new IllegalArgumentException("Mismatch of WOCE flags; " +
									"previous: '" + woceFlag + "'; current: '" + givenFlag + "'");
					}
					else {
						// Assume it is the data variable name.
						// Note that WOCE from just lat/lon/date plots will not have this column
						if ( dataName == null )
							dataName = name;
						else if ( ! dataName.equals(name) )
							throw new IllegalArgumentException("Mismatch of data names; " +
									"previous: '" + dataName + "'; current: '" + name + "'");
						dataValue = Double.parseDouble(value);
					}

					if ( woceName == null )
						throw new IllegalArgumentException("No WOCE flag name given");
					if ( expocode == null ) 
						throw new IllegalArgumentException("No expocode given with WOCE flag");
					if ( dataDate == null )
						throw new IllegalArgumentException("No data point date given with WOCE flag");
					if ( longitude == null )
						throw new IllegalArgumentException("No data point longitude given with WOCE flag");
					if ( latitude == null )
						throw new IllegalArgumentException("No data point latitude given with WOCE flag");
					// dataValue could be null if issue is only on lon/lat/time

					// TODO: Save this lon/lat/time and possibly data value for the WOCE flag

				}
			}
		} catch ( Exception ex ) {
			logerror(request, "Problems interpreting the WOCE flags", ex);
			if ( expocode != null )
				logerror(request, "expocode = " + expocode, "");
			if ( dataName != null )
				logerror(request, "dataName = " + dataName, "");
			if ( woceName != null )
				logerror(request, "woceName = " + woceName, "");
			if ( woceFlag != null )
				logerror(request, "woceFlag = " + woceFlag, "");
			return ERROR;
		}

		if ( expocode == null ) {
			logerror(request, "No EXPOCODE given in the WOCE flags", "");
			return ERROR;
		}
		if ( woceName == null ) {
			logerror(request, "No WOCE flag name given in the WOCE flags", "");
			return ERROR;
		}
		if ( woceFlag == null ) {
			logerror(request, "No WOCE flag value given in the WOCE flags", "");
			return ERROR;
		}
		// dataName could be null if issue is only on lon/lat/time

		// TODO: Save these WOCE flags, updating the LAS temporary DSG file
		
		request.setAttribute("expocode", expocode);
		return EDITS;
	}

}
