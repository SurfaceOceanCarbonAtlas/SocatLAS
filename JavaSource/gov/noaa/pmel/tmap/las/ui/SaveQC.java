package gov.noaa.pmel.tmap.las.ui;

import java.io.UnsupportedEncodingException;

import javax.xml.bind.DatatypeConverter;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import gov.noaa.pmel.tmap.exception.LASException;
import gov.noaa.pmel.tmap.las.jdom.JDOMUtils;
import gov.noaa.pmel.tmap.las.jdom.LASUIRequest;
import gov.noaa.pmel.tmap.las.product.server.LASAction;

public class SaveQC extends LASAction {

	private static final long serialVersionUID = 5887938420589369612L;

	private static Logger log = LoggerFactory.getLogger(SaveQC.class.getName());

	private static String ERROR = "error";
	private static String QC = "qc";

	private boolean configured;

	/**
	 * Creates with the SOCAT UploadDashboard DsgNcFileHandler and DatabaseRequestHandler
	 * 
	 * @throws IllegalArgumentException
	 * 		if parameters are invalid
	 * @throws SQLException
	 * 		if one is thrown connecting to the database
	 * @throws LASException 
	 * 		if unable to get the database parameters
	 */
	public SaveQC() {
		super();
		log.debug("Initializing SaveQC from database configuraton");
		configured = false;

		// TODO: initialized and set configured to true (or remove/replace it)

	}

	@Override
	public String execute() throws Exception {
		// Make sure this is configured for setting WOCE flags
		if ( ! configured ) {
			logerror(request, "LAS not configured to allow editing of QC flags", "Illegal action");
			return ERROR;
		}

		// Get the request from the query parameter.
		String requestXML = request.getParameter("xml");

		// Get the lasRequest object from the request.  It was placed there by the RequestInputFilter.
		LASUIRequest lasRequest = (LASUIRequest) request.getAttribute("las_request");

		// If it wasn't built in the filter try to build it here
		if ( (lasRequest == null) && ( (requestXML != null) && ! requestXML.equals("") ) ) {
			try {
				String temp = JDOMUtils.decode(requestXML, "UTF-8");
				requestXML = temp;
			} catch (UnsupportedEncodingException e) {
				LASAction.logerror(request, "Error decoding the XML request query string.", e);
				return ERROR;
			}

			// Create a lasRequest object.
			lasRequest = new LASUIRequest();
			try {
				JDOMUtils.XML2JDOM(requestXML, lasRequest);
				// Set the lasRequest object in the HttpServletRequest so the product server does not have to rebuild it.
				request.setAttribute("las_request", lasRequest);
			} catch (Exception e) {
				LASAction.logerror(request, "Error parsing the request XML. ", e);
				return ERROR;
			}
		}

		String expocode = lasRequest.getProperty("qc", "cruise_ID");
		String regionIDs = lasRequest.getProperty("qc", "region_IDs");
		String flag = lasRequest.getProperty("qc", "flag");
		String comment;
		try {
			String encodedComment = lasRequest.getProperty("qc", "comment");
			comment = new String(DatatypeConverter.parseHexBinary(encodedComment), "UTF-16");
		} catch ( Exception ex ) {
			logerror(request, "Unable to get the comment for QC flagging", ex);
			return ERROR;
		}
		String reviewer = lasRequest.getProperty("qc", "reviewer");

		if ( expocode.isEmpty() ) {
			logerror(request, "No expocode specified", "");
			return ERROR;
		}
		if ( regionIDs.isEmpty() ) {
			logerror(request, "No region ID specified", "");
			return ERROR;
		}
		if ( flag.isEmpty() ) {
			// Empty flag is acceptable - just a QC comment
			flag = " ";
		}
		if ( comment.isEmpty() ) {
			logerror(request, "No comment provided", "");
			return ERROR;
		}

		// Validate the reviewer assigning this QC flag
		String username;
		try {
			log.debug("Validating SaveQC reviewer");
			username = request.getUserPrincipal().getName();
		} catch ( Exception ex ) {
			logerror(request, "Unable to get the username for QC flagging", ex);
			return ERROR;
		}
		if ( (username == null) || ! username.equalsIgnoreCase(reviewer) ) {
			logerror(request, "Invalid username " + username + " for reviewer " + reviewer, "");
			return ERROR;
		}

		// If a global flag is in the list of regions, 
		// only assign the global flag and ignore other regions
		if ( regionIDs.contains("G") ) {
			regionIDs = "G";
		}

		// TODO: Assign the QC flag

		return QC;
	}

}
