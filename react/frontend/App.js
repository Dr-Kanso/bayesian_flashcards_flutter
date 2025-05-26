import React, { useState, useEffect } from "react";
import axios from "axios";
import ReactQuill from "react-quill";
import "react-quill/dist/quill.snow.css";
import './App.css';

const API_BASE = "http://localhost:5002";
const API = `${API_BASE}/api`;  // Updated port from 5001 to 5002
const DEFAULT_USER = "default";

// Custom CreateDeckModal component
const CreateDeckModal = ({ onClose, onSubmit }) => {
  const [deckName, setDeckName] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState('');
  
  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!deckName.trim()) {
      setError('Please enter a deck name');
      return;
    }
    
    setIsSubmitting(true);
    setError('');
    
    // Track request status
    console.log(`Attempting to create deck: "${deckName}"`);
    
    try {
      onSubmit(deckName.trim());
    } catch (error) {
      console.error("Error submitting form:", error);
      setError('Error submitting form');
    } finally {
      setIsSubmitting(false);
    }
  };
  
  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal-content create-deck-modal" onClick={e => e.stopPropagation()}>
        <h2>Create New Deck</h2>
        <form onSubmit={handleSubmit}>
          {error && <div className="error-message">{error}</div>}
          <input
            type="text"
            value={deckName}
            onChange={(e) => setDeckName(e.target.value)}
            placeholder="Enter deck name"
            className="deck-name-input"
            autoFocus
          />
          <div className="modal-buttons">
            <button type="button" onClick={onClose} className="cancel-button">Cancel</button>
            <button type="submit" className="create-button" disabled={isSubmitting}>
              {isSubmitting ? 'Creating...' : 'Create'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

// ImageModal component for displaying enlarged images
const ImageModal = ({ image, alt, onClose }) => {
  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal-content" onClick={e => e.stopPropagation()}>
        <img src={image} alt={alt} />
        <button className="modal-close" onClick={onClose}>×</button>
      </div>
    </div>
  );
};

// ZoomableImage component declaration remains outside

// ZoomableImage component for any image that should be enlargeable
const ZoomableImage = ({ src, alt, className }) => {
  const [isModalOpen, setIsModalOpen] = useState(false);
  
  return (
    <>
      <div className="image-wrapper" onClick={() => setIsModalOpen(true)}>
        <img src={src} alt={alt} className={className} />
        <div className="zoom-icon">🔍</div>
      </div>
      
      {isModalOpen && (
        <div className="modal-overlay" onClick={() => setIsModalOpen(false)}>
          <div className="modal-content" onClick={e => e.stopPropagation()}>
            <img src={src} alt={alt} className="fullsize-image" />
            <button className="modal-close" onClick={() => setIsModalOpen(false)}>×</button>
          </div>
        </div>
      )}
    </>
  );
};

// TimerModal component for displaying "Time's up!" notification
const TimerModal = ({ onClose }) => {
  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal-content timer-modal-content" onClick={e => e.stopPropagation()}>
        <h2>Time's Up!</h2>
        <p>Your review session timer has ended.</p>
        <button className="timer-btn continue-btn" onClick={onClose}>Continue</button>
      </div>
    </div>
  );
};

const ImageDropZone = ({ onDrop, image, onRemove, side }) => {
  const [isDragActive, setIsDragActive] = useState(false);

  const handleDragOver = (e) => {
    e.preventDefault();
    setIsDragActive(true);
  };

  const handleDragLeave = () => {
    setIsDragActive(false);
  };

  const handleDrop = (e) => {
    e.preventDefault();
    setIsDragActive(false);
    const file = e.dataTransfer.files[0];
    if (file && file.type.startsWith('image/')) {
      const reader = new FileReader();
      reader.onloadend = () => onDrop(reader.result);
      reader.readAsDataURL(file);
    }
  };

  return (
    <div className={`image-drop-zone ${isDragActive ? 'drag-active' : ''}`}
         onDragOver={handleDragOver}
         onDragLeave={handleDragLeave}
         onDrop={handleDrop}>
      {image ? (
        <div className="image-preview-container">
          <img src={image} alt={`${side} preview`} className="image-preview" />
          <button className="remove-image" onClick={onRemove}>×</button>
        </div>
      ) : (
        <p>Drag and drop an image here</p>
      )}
    </div>
  );
};

function App() {
  const [decks, setDecks] = useState([]);
  const [currentDeck, setCurrentDeck] = useState(null);
  const [view, setView] = useState('decks'); // 'decks', 'add', 'review', 'stats', 'manage'
  const [deck, setDeck] = useState([]);
  const [front, setFront] = useState("");
  const [back, setBack] = useState("");
  const [frontImage, setFrontImage] = useState(null);
  const [backImage, setBackImage] = useState(null);
  const [reviewCard, setReviewCard] = useState(null);
  const [showBack, setShowBack] = useState(false);
  const [rating, setRating] = useState(10);
  const [cardType, setCardType] = useState("Basic");
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingCard, setEditingCard] = useState(null);
  const [showCreateDeckModal, setShowCreateDeckModal] = useState(false);

  const [timer, setTimer] = useState(60); // 1 minute default
  const [isTimerRunning, setIsTimerRunning] = useState(false);
  const [timerInterval, setTimerInterval] = useState(null);
  
  // Session management
  const [currentSession, setCurrentSession] = useState(null);
  const [sessions, setSessions] = useState([]);
  const [statsType, setStatsType] = useState('user'); // 'user', 'deck', 'session'
  const [selectedSession, setSelectedSession] = useState(null);

  // Adding state to control which tab is active in the Manage view
  const [manageTab, setManageTab] = useState('cards'); // 'cards' or 'sessions'

  const toolbarId = 'toolbar';
  const formats = ['header', 'bold', 'italic', 'underline', 'list', 'bullet', 'link'];
  const modules = {
    toolbar: {
      container: '#' + toolbarId,
      handlers: {}
    }
  };
  
  const toolbarOptions = [
    [{ 'header': [1, 2, false] }],
    ['bold', 'italic', 'underline'],
    ['link'],
    [{ 'list': 'ordered'}, { 'list': 'bullet' }]
  ];

  // Load all decks
  
  // Handle URL parameters and postMessage events
  useEffect(() => {
    // Function to handle URL parameters
    const handleUrlParams = () => {
      const urlParams = new URLSearchParams(window.location.search);
      const deckParam = urlParams.get('deck');
      
      // If deck parameter is present, set the current deck and switch to add view
      if (deckParam) {
        console.log('URL parameter found, deck:', deckParam);
        // Check if the deck exists in our list
        if (decks.includes(deckParam)) {
          setCurrentDeck(deckParam);
          setView('add');
        } else {
          console.warn('Deck specified in URL not found:', deckParam);
        }
      }
    };
    
    // Handle URL parameters on load
    handleUrlParams();
    
    // Function to handle postMessage events from the native app
    const handlePostMessage = (event) => {
      console.log('Received postMessage:', event.data);
      try {
        const data = JSON.parse(event.data);
        
        // Handle OPEN_ADD_CARD message type
        if (data.type === 'OPEN_ADD_CARD' && data.deck) {
          console.log('Opening add card view for deck:', data.deck);
          // Check if the deck exists in our list
          if (decks.includes(data.deck)) {
            setCurrentDeck(data.deck);
            setView('add');
          } else {
            console.warn('Deck specified in message not found:', data.deck);
          }
        }
      } catch (error) {
        console.error('Error parsing postMessage data:', error);
      }
    };
    
    // Add event listener for postMessage
    window.addEventListener('message', handlePostMessage);
    
    // Expose functions to window for direct access from WebView
    window.setView = setView;
    window.setCurrentDeck = setCurrentDeck;
    
    // Clean up event listener
    return () => {
      window.removeEventListener('message', handlePostMessage);
    };
  }, [decks]); // Re-run when decks list changes
useEffect(() => {
    axios.get(`${API}/decks`).then(res => setDecks(res.data));
  }, []);

  // Load deck cards when deck changes
  useEffect(() => {
    if (currentDeck) {
      axios.get(`${API}/cards/${currentDeck}`).then(res => setDeck(res.data));
    }
  }, [currentDeck]);

  // Cleanup timer when changing views
  useEffect(() => {
    if (view !== 'review') {
      stopTimer();
      resetTimer();
    }
  }, [view]);

  // Session management functions
  const startStudySession = async () => {
    try {
      const sessionName = prompt("Enter a name for this study session (or leave blank for default):");
      
      // If user clicks cancel (sessionName is null), return to decks view
      if (sessionName === null) {
        setView('decks');
        return;
      }
      
      // Check if currentDeck is valid
      if (!currentDeck) {
        alert("Please select a deck before studying.");
        setView('decks');
        return;
      }
      
      console.log("About to make API call with data:", {
        deck: currentDeck,
        user: DEFAULT_USER,
        name: sessionName || undefined
      });
      
      // Show loading indicator or message in console
      console.log("Creating study session...");
      
      const response = await axios.post(`${API}/sessions`, {
        deck: currentDeck,
        user: DEFAULT_USER,
        name: sessionName || undefined
      });
      
      console.log("API response for session creation:", response.data);
      
      if (response.data.success) {
        console.log("Session created successfully, data:", response.data.session);
        setCurrentSession(response.data.session);
        
        // Wait a moment for the session to be properly registered in the backend
        await new Promise(resolve => setTimeout(resolve, 500));
        
        setView('review');
        resetTimer();
        
        // Get the first card with retry logic
        try {
          await getNextCard();
          startTimer();
        } catch (cardError) {
          console.error("Failed to get first card, retrying once:", cardError);
          // Wait a bit longer and try again
          await new Promise(resolve => setTimeout(resolve, 1000));
          await getNextCard();
          startTimer();
        }
      } else {
        console.error("Session creation failed, response:", response.data);
        alert(`Failed to create study session: ${response.data.error || 'Unknown error'}`);
      }
    } catch (error) {
      console.error("Error creating study session:", error);
      let errorMsg = "Failed to create study session. Please try again.";
      
      if (error.response) {
        console.error("Error response:", error.response.data);
        if (error.response.data && error.response.data.error) {
          errorMsg = `Failed to create study session: ${error.response.data.error}`;
          
          // Provide more specific guidance based on error message
          if (error.response.data.error.includes("no cards")) {
            errorMsg = "This deck has no cards. Please add some cards before studying.";
          }
        }
      } else if (error.request) {
        errorMsg = "Failed to create study session: No response from server. Is the backend running?";
      }
      
      alert(errorMsg);
      // Return to decks view on error as well
      setView('decks');
    }
  };
  
  const endStudySession = async () => {
    if (!currentSession) return;
    
    try {
      await axios.post(`${API}/sessions/${currentSession.id}/end`);
      setCurrentSession(null);
      setView('stats');
      loadSessions();
    } catch (error) {
      console.error("Error ending study session:", error);
    }
  };
  
  const loadSessions = async () => {
    try {
      const response = await axios.get(`${API}/sessions?user=${DEFAULT_USER}${currentDeck ? `&deck=${currentDeck}` : ''}`);
      setSessions(response.data);
    } catch (error) {
      console.error("Error loading sessions:", error);
    }
  };
  
  // Load sessions when component mounts or when current deck changes
  useEffect(() => {
    loadSessions();
  }, [currentDeck]);

  const startTimer = () => {
    if (!isTimerRunning) {
      setIsTimerRunning(true);
      const interval = setInterval(() => {
        setTimer((prev) => {
          if (prev <= 1) {
            clearInterval(interval);
            setIsTimerRunning(false);
            // Show timer modal when time is up
            setIsModalOpen(true);
            return 60; // Reset to 1 minute
          }
          return prev - 1;
        });
      }, 1000);
      setTimerInterval(interval);
    }
  };

  const stopTimer = () => {
    if (timerInterval) {
      clearInterval(timerInterval);
      setTimerInterval(null);
    }
    setIsTimerRunning(false);
  };

  const resetTimer = () => {
    stopTimer();
    setTimer(60);
  };

  (function() {
  console.log('Navigation patch loading...');
  
  // Add global navigation guard
  window.addEventListener('beforeunload', async (event) => {
    if (window.electronAPI && window.electronAPI.checkActiveSession) {
      const hasActiveSession = await window.electronAPI.checkActiveSession();
      if (hasActiveSession) {
        event.preventDefault();
        event.returnValue = '';
        
        const shouldNavigate = await window.electronAPI.confirmNavigation();
        if (shouldNavigate) {
          // Allow navigation after confirmation
          window.electronAPI.endSession();
          return;
        }
        
        return false;
      }
    }
  });
  
  // Patch navigation links
  document.addEventListener('click', async (event) => {
    // Find closest anchor or button
    const link = event.target.closest('a, button');
    
    if (!link) return;
    
    // Check if we have an active session
    if (window.electronAPI && window.electronAPI.checkActiveSession) {
      const hasActiveSession = await window.electronAPI.checkActiveSession();
      if (hasActiveSession) {
        // Prevent default navigation
        event.preventDefault();
        
        // Show confirmation
        const shouldNavigate = await window.electronAPI.confirmNavigation();
        if (shouldNavigate) {
          // End session and continue
          await window.electronAPI.endSession();
          
          // If it was a link, follow it
          if (link.href) {
            window.location.href = link.href;
          }
        }
      }
    }
  });
  
  console.log('Navigation patch loaded');
})();

  // Navigation bar component
  const NavigationBar = () => (
    <div className="nav-bar">
      <button 
        className={`nav-button ${view === 'decks' ? 'active' : ''}`} 
        onClick={() => setView('decks')}
      >
        Decks
      </button>
      <button 
        className={`nav-button ${view === 'add' ? 'active' : ''}`} 
        onClick={() => setView('add')}
      >
        Add
      </button>
      <button 
        className={`nav-button ${view === 'manage' ? 'active' : ''}`} 
        onClick={() => setView('manage')}
      >
        Manage
      </button>
      <button 
        className={`nav-button ${view === 'stats' ? 'active' : ''}`} 
        onClick={() => setView('stats')}
      >
        Stats
      </button>
      {view === 'review' && (
        <div className="timer-container">
          <span className="timer-display">{Math.floor(timer / 60)}:{(timer % 60).toString().padStart(2, '0')}</span>
          <button className="timer-button" onClick={isTimerRunning ? stopTimer : startTimer}>
            {isTimerRunning ? '⏸' : '▶'}
          </button>
          <button className="timer-button" onClick={resetTimer}>↺</button>
        </div>
      )}
    </div>
  );

  // Handle image upload for card front and back
  const handleImageUpload = (e, side) => {
    const file = e.target.files[0];
    const reader = new FileReader();
    reader.onloadend = () => {
      if (side === 'front') {
        setFrontImage(reader.result);
      } else {
        setBackImage(reader.result);
      }
    };
    if (file) {
      reader.readAsDataURL(file);
    }
  };

  // Add new card
  const handleAddCard = async () => {
    if (!currentDeck) {
      alert("Please select a deck first");
      return;
    }
    await axios.post(`${API}/cards/${currentDeck}`, {
      front,
      back,
      frontImage,
      backImage,
      type: cardType
    });
    setFront("");
    setBack("");
    setFrontImage(null);
    setBackImage(null);
    axios.get(`${API}/cards/${currentDeck}`).then(res => setDeck(res.data));
  };

  // Create new deck 
  const handleCreateDeck = async (name) => {
    try {
      console.log(`Creating deck: ${name}`);
      console.log(`API URL: ${API}/decks`);
      
      // Make the API call using Axios like other functions in the app
      const response = await axios.post(`${API}/decks`, { deck: name });
      console.log('Create deck response:', response.data);
      
      if (response.data.success) {
        // Refresh the decks list
        const decksResponse = await axios.get(`${API}/decks`);
        console.log('Updated decks list:', decksResponse.data);
        setDecks(decksResponse.data);
        setCurrentDeck(name); // Select the newly created deck
        alert(response.data.message || 'Deck created successfully!');
      } else {
        console.error('Create deck failed:', response.data);
        alert(`Failed to create deck: ${response.data.error || 'Unknown error'}`);
      }
    } catch (error) {
      console.error("Error creating deck:", error);
      if (error.response) {
        // The request was made and the server responded with a status code
        // that falls out of the range of 2xx
        console.error('Response data:', error.response.data);
        console.error('Response status:', error.response.status);
        alert(`Failed to create deck: ${error.response.data.error || error.message}`);
      } else if (error.request) {
        // The request was made but no response was received
        console.error('No response received:', error.request);
        alert('Failed to create deck: No response from server');
      } else {
        // Something happened in setting up the request that triggered an Error
        alert(`Failed to create deck: ${error.message}`);
      }
    }
  };

  // Get next card to review
  const getNextCard = async () => {
    if (!currentDeck) return;
    try {
      console.log(`Getting next card for deck: ${currentDeck} and user: ${DEFAULT_USER}`);
      
      // Add a timestamp to prevent caching issues
      const timestamp = new Date().getTime();
      const res = await axios.post(`${API}/next_card/${currentDeck}/${DEFAULT_USER}?_=${timestamp}`);
      console.log("Next card response:", res.data);
      
      if (res.data && res.data.success && res.data.next_card) {
        setReviewCard(res.data.next_card);
        setShowBack(false);
        setRating(10);
      } else {
        console.error("Invalid response format:", res.data);
        alert("Error: Could not load next card. The response format was invalid.");
        // Go back to decks view
        setView('decks');
      }
    } catch (error) {
      console.error("Error getting next card:", error);
      let errorMsg = error.message;
      
      // Extract the specific error message if available
      if (error.response && error.response.data && error.response.data.error) {
        errorMsg = error.response.data.error;
        console.error("Error response data:", error.response.data);
        console.error("Error response status:", error.response.status);
      }
      
      alert(`Error getting next card: ${errorMsg}`);
      // Go back to decks view on error
      setView('decks');
      
      // Rethrow the error to allow the caller to handle it if needed
      throw error;
    }
  };

  // Submit review
  const handleReview = async () => {
    try {
        console.log('Submitting review:', { 
            id: reviewCard.id, 
            rating: rating,
            session_id: currentSession ? currentSession.id : null
        });
        
        // Add a timestamp to prevent caching issues
        const timestamp = new Date().getTime();
        const response = await axios.post(`${API}/review/${currentDeck}/${DEFAULT_USER}?_=${timestamp}`, {
            id: reviewCard.id,
            rating: rating,
            session_id: currentSession ? currentSession.id : null
        });
        
        console.log('Review response:', response.data);
        
        if (response.data.success && response.data.next_card) {
            console.log('Setting next card:', response.data.next_card);
            stopTimer();
            resetTimer();
            setReviewCard(response.data.next_card);
            setShowBack(false);
            setRating(10);
            startTimer();
        } else {
            console.error('Invalid response format:', response.data);
            // Try to extract a more detailed error message if available
            const errorMsg = response.data.error || 'Could not load next card. Please try again.';
            alert(`Error: ${errorMsg}`);
            
            // If the error indicates no more cards, go back to decks view
            if (response.data.error && response.data.error.includes('No more cards')) {
                alert('You have completed all available cards in this deck!');
                setView('decks');
            }
        }
    } catch (error) {
        console.error("Error submitting review:", error);
        let errorMsg = 'Error submitting review. Please try again.';
        
        if (error.response && error.response.data) {
            console.error('Error response:', error.response.data);
            errorMsg = error.response.data.error || errorMsg;
        }
        
        alert(errorMsg);
        
        // If there's a critical error, go back to decks view
        if (error.response && error.response.status >= 500) {
            setView('decks');
        }
    }
  };

  // Delete card function
  const handleDeleteCard = async (cardId) => {
    if (!currentDeck) return;
    
    if (window.confirm("Are you sure you want to delete this card?")) {
      try {
        await axios.delete(`${API}/cards/${currentDeck}/${cardId}`);
        // Refresh the cards list
        axios.get(`${API}/cards/${currentDeck}`).then(res => setDeck(res.data));
      } catch (error) {
        console.error("Error deleting card:", error);
        alert("Failed to delete card. Please try again.");
      }
    }
  };
  
  // Edit card setup function
  const handleEditCardSetup = (card) => {
    setEditingCard(card);
    setFront(card.front);
    setBack(card.back);
    setFrontImage(card.frontImage);
    setBackImage(card.backImage);
    setCardType(card.type || "Basic");
    setView('add');
  };
  
  // Update card function
  const handleUpdateCard = async () => {
    if (!currentDeck || !editingCard) return;
    
    try {
      await axios.put(`${API}/cards/${currentDeck}/${editingCard.id}`, {
        front,
        back,
        frontImage,
        backImage,
        type: cardType
      });
      
      // Clear the form
      setFront("");
      setBack("");
      setFrontImage(null);
      setBackImage(null);
      setCardType("Basic");
      setEditingCard(null);
      
      // Refresh the cards list
      axios.get(`${API}/cards/${currentDeck}`).then(res => setDeck(res.data));
      
      // Return to manage view
      setView('manage');
    } catch (error) {
      console.error("Error updating card:", error);
      alert("Failed to update card. Please try again.");
    }
  };

  // Delete session function
  const handleDeleteSession = async (sessionId) => {
    if (window.confirm("Are you sure you want to delete this session? This action cannot be undone.")) {
      try {
        // Immediately update UI by removing the session from the local state
        setSessions(prevSessions => prevSessions.filter(session => session.id !== sessionId));
        
        // If the deleted session was selected, clear the selection
        if (selectedSession === sessionId) {
          setSelectedSession(null);
        }

        // Then call the API to actually delete the session
        await axios.post(`${API}/sessions/${sessionId}/end`);
        
        // No need to call loadSessions() here as we've already updated the UI
        // This avoids any potential flickering
      } catch (error) {
        console.error("Error deleting session:", error);
        alert("Failed to delete session. Please try again.");
        // If there was an error, reload the sessions to restore the UI
        loadSessions();
      }
    }
  };
  
  // Render deck selection view
  const DeckView = () => (
    <div className="deck-view">
      <div className="deck-header">
        <h2>Your Decks</h2>
        <button 
          className="study-button"
          onClick={() => {
            if (currentDeck) {
              startStudySession();
            } else {
              alert("Please select a deck first");
            }
          }}
        >
          Study
        </button>
      </div>
      <div className="deck-grid">
        {decks.map(deck => (
          <div 
            key={deck}
            className={`deck-card ${currentDeck === deck ? 'selected' : ''}`}
            onClick={() => {
              setCurrentDeck(deck);
              // Stay on the deck view after selecting a deck
              // This allows the Study button to highlight without starting a session
            }}
          >
            <h3>{deck}</h3>
            <p>{deck.length || 0} cards</p>
          </div>
        ))}
        <div 
          className="deck-card new-deck"
          onClick={() => {
            console.log("Create New Deck button clicked");
            console.log("Current showCreateDeckModal state:", showCreateDeckModal);
            setShowCreateDeckModal(true);
            console.log("Updated showCreateDeckModal state:", true);
          }}
        >
          <h3>+ Create New Deck</h3>
        </div>
      </div>
    </div>
  );

  // Render stats view
  const StatsView = () => (
    <div className="stats-view">
      <h2>Statistics</h2>
      
      <div className="stats-filters">
        <div className="filter-group">
          <label>Stats Type:</label>
          <select
            value={statsType}
            onChange={(e) => setStatsType(e.target.value)}
            className="stats-selector"
          >
            <option value="user">User Statistics</option>
            <option value="deck">Deck Statistics</option>
            <option value="session">Session Statistics</option>
          </select>
        </div>
        
        {statsType === 'session' && (
          <div className="filter-group">
            <label>Session:</label>
            <select
              value={selectedSession || ''}
              onChange={(e) => setSelectedSession(e.target.value)}
              className="stats-selector"
            >
              <option value="">Select a session</option>
              {sessions.map(session => (
                <option key={session.id} value={session.id}>
                  {session.name} ({new Date(session.start_time).toLocaleDateString()})
                </option>
              ))}
            </select>
          </div>
        )}
      </div>
      
      <div className="session-list">
        {statsType === 'session' && sessions.length > 0 && (
          <div className="sessions-container">
            <h3>Study Sessions</h3>
            <table className="sessions-table">
              <thead>
                <tr>
                  <th>Name</th>
                  <th>Date</th>
                  <th>Duration</th>
                  <th>Cards Studied</th>
                  <th>Success Rate</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                {sessions.map(session => (
                  <tr key={session.id} className={selectedSession === session.id ? 'selected-row' : ''}>
                    <td>{session.name}</td>
                    <td>{new Date(session.start_time).toLocaleDateString()}</td>
                    <td>{Math.round(session.duration)} minutes</td>
                    <td>{session.cards_studied}</td>
                    <td>{Math.round(session.success_rate * 100)}%</td>
                    <td>
                      <button onClick={() => setSelectedSession(session.id)}>
                        View Stats
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
      
      <div className="stats-container">
        <ZoomableImage 
          src={
            statsType === 'session' && selectedSession
              ? `${API}/stats/session?session=${selectedSession}&user=${DEFAULT_USER}&t=${Date.now()}`
              : statsType === 'deck'
              ? `${API}/stats/deck?deck=${currentDeck}&user=${DEFAULT_USER}&t=${Date.now()}`
              : `${API}/stats/user?user=${DEFAULT_USER}&t=${Date.now()}`
          } 
          alt="Performance Statistics" 
          className="stats-image"
        />
      </div>
    </div>
  );

  // Render card management view
  const ManageView = () => (
    <div className="manage-view">
      <h2>{currentDeck ? `Manage Cards in ${currentDeck}` : 'Manage Your Flashcards'}</h2>
      
      <div className="deck-actions">
        <select 
          value={currentDeck || ''} 
          onChange={(e) => setCurrentDeck(e.target.value)}
          className="deck-selector"
        >
          <option value="">Select a deck</option>
          {decks.map(deck => (
            <option key={deck} value={deck}>{deck}</option>
          ))}
        </select>
        
        {currentDeck && (
          <button 
            onClick={() => {
              setEditingCard(null);
              setFront("");
              setBack("");
              setFrontImage(null);
              setBackImage(null);
              setCardType("Basic");
              setView('add');
            }}
            className="add-new-button"
          >
            Add New Card
          </button>
        )}
      </div>
      
      <div className="manage-tabs">
        <button 
          className={`manage-tab ${manageTab === 'cards' ? 'active' : ''}`} 
          onClick={() => setManageTab('cards')}
        >
          Cards
        </button>
        <button 
          className={`manage-tab ${manageTab === 'sessions' ? 'active' : ''}`} 
          onClick={() => setManageTab('sessions')}
        >
          Sessions
        </button>
      </div>
      
      {manageTab === 'cards' ? (
        !currentDeck ? (
          <div className="no-cards-message">
            <p>Please select a deck from the dropdown above to manage its cards.</p>
          </div>
        ) : deck.length === 0 ? (
          <div className="no-cards-message">
            <p>This deck has no cards yet. Click "Add New Card" to create your first card.</p>
          </div>
        ) : (
          <div className="cards-list">
            {deck.map(card => (
              <div key={card.id} className="card-item">
                <div className="card-preview">
                  <div className="card-preview-front">
                    <h4>Front</h4>
                    <div className="preview-content">
                      <div dangerouslySetInnerHTML={{ __html: card.front }} />
                      {card.frontImage && (
                        <img src={card.frontImage} alt="Front" className="preview-image" />
                      )}
                    </div>
                  </div>
                  
                  <div className="card-preview-back">
                    <h4>Back</h4>
                    <div className="preview-content">
                      <div dangerouslySetInnerHTML={{ __html: card.back }} />
                      {card.backImage && (
                        <img src={card.backImage} alt="Back" className="preview-image" />
                      )}
                    </div>
                  </div>
                </div>
                
                <div className="card-actions">
                  <button 
                    onClick={() => handleEditCardSetup(card)} 
                    className="edit-button"
                  >
                    Edit
                  </button>
                  <button 
                    onClick={() => handleDeleteCard(card.id)} 
                    className="delete-button"
                  >
                    Delete
                  </button>
                </div>
              </div>
            ))}
          </div>
        )
      ) : (
        <div className="sessions-list">
          {sessions.length === 0 ? (
            <p>No study sessions found. Start a new session to begin.</p>
          ) : (
            <table className="sessions-table">
              <thead>
                <tr>
                  <th>Name</th>
                  <th>Date</th>
                  <th>Duration</th>
                  <th>Cards Studied</th>
                  <th>Success Rate</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                {sessions.map(session => (
                  <tr key={session.id}>
                    <td>{session.name}</td>
                    <td>{new Date(session.start_time).toLocaleDateString()}</td>
                    <td>{Math.round(session.duration)} minutes</td>
                    <td>{session.cards_studied}</td>
                    <td>{Math.round(session.success_rate * 100)}%</td>
                    <td>
                      <button onClick={() => {
                        setSelectedSession(session.id);
                        setStatsType('session');
                        setView('stats');
                      }}>
                        View Stats
                      </button>
                      <button onClick={() => handleDeleteSession(session.id)}>
                        Delete
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
      )}
    </div>
  );

  // Footer masthead component
  const FooterMasthead = () => (
    <div className="footer-masthead">
      <div className="app-name">Bayesian Flashcards</div>
      <div className="author">by Leon Chlon</div>
    </div>
  );

  // Load sessions when view changes to manage and when manageTab changes to sessions
  useEffect(() => {
    if (view === 'manage' && manageTab === 'sessions') {
      loadSessions();
    }
  }, [view, manageTab]);

  // Session management functions
  
  // Navigation guard function - moved inside component
  const handleNavigation = async (destination) => {
    if (await window.electronAPI.checkActiveSession()) {
      const canNavigate = await window.electronAPI.confirmNavigation();
      if (canNavigate) {
        // End the session and save progress
        await endAndSaveSession();
        // Navigate to destination
        setView(destination);
      }
    } else {
      setView(destination);
    }
  };

  // Session end handler - moved inside component
  const endAndSaveSession = async () => {
    try {
      // Make API call to save session progress if we have a current session
      if (currentSession && currentSession.id) {
        await axios.post('/api/sessions/end', { sessionId: currentSession.id });
        await window.electronAPI.endSession();
      }
    } catch (error) {
      console.error('Error ending session:', error);
    }
  };

  // Alternative study session start - moved inside component
  const handlePromptStudySession = async (deckName) => {
    const sessionName = await window.electronAPI.showPromptDialog(
      'Enter a name for this study session',
      `Session ${new Date().toLocaleString()}`
    );
    
    if (sessionName === null) {
      // User cancelled - return to decks screen
      setView('decks');
      return;
    }
    
    // Continue with session creation
    try {
      const response = await axios.post('/api/sessions/create', {
        deckName,
        sessionName
      });
      // ... rest of the session creation logic
    } catch (error) {
      console.error('Error creating study session:', error);
    }
  };

  return (
    <div className="app-container">
      <NavigationBar />
      
      {view === 'add' && (
        <div className="card-editor">
          <div className="editor-header">
            <select 
              value={currentDeck || ''} 
              onChange={(e) => setCurrentDeck(e.target.value)}
              className="deck-selector"
            >
              <option value="">Select a deck</option>
              {decks.map(deck => (
                <option key={deck} value={deck}>{deck}</option>
              ))}
            </select>
            <div id={toolbarId} className="toolbar-only">
              <ReactQuill
                modules={{ toolbar: toolbarOptions }}
                className="toolbar-only"
              />
            </div>
          </div>

          <div className="card-side">
            <h3>Front</h3>
            <ReactQuill 
              value={front} 
              onChange={setFront}
              modules={modules}
              formats={formats}
              className="editor-field"
            />
            <ImageDropZone
              onDrop={setFrontImage}
              image={frontImage}
              onRemove={() => setFrontImage(null)}
              side="front"
            />
          </div>

          <div className="card-side">
            <h3>Back</h3>
            <ReactQuill 
              value={back} 
              onChange={setBack}
              modules={modules}
              formats={formats}
              className="editor-field"
            />
            <ImageDropZone
              onDrop={setBackImage}
              image={backImage}
              onRemove={() => setBackImage(null)}
              side="back"
            />
          </div>

          <div className="editor-footer">
            {editingCard ? (
              <div className="editor-actions">
                <button onClick={handleUpdateCard} className="update-button">Update Card</button>
                <button 
                  onClick={() => {
                    setEditingCard(null);
                    setFront("");
                    setBack("");
                    setFrontImage(null);
                    setBackImage(null);
                    setCardType("Basic");
                    setView('manage');
                  }} 
                  className="cancel-button"
                >
                  Cancel
                </button>
              </div>
            ) : (
              <button onClick={handleAddCard} className="add-button">Add Card</button>
            )}
          </div>
        </div>
      )}
      
      {view === 'review' && (
        <div className="review-container">
          {currentSession && (
            <div className="active-session-info">
              <div className="session-details">
                <h3>Active Session: {currentSession.name}</h3>
                <p>Started: {new Date(currentSession.start_time).toLocaleTimeString()}</p>
              </div>
              <button 
                onClick={endStudySession} 
                className="end-session-btn"
              >
                End Session
              </button>
            </div>
          )}
          
          {reviewCard ? (
            <div className="review-card">
              <div className="card-content">
                <div className="card-text" dangerouslySetInnerHTML={{ __html: reviewCard.front }} />
                {reviewCard.frontImage && (
                  <ZoomableImage src={reviewCard.frontImage} alt="Front" className="card-image" />
                )}
              </div>
              
              {showBack ? (
                <div className="back-content">
                  <div className="card-text" dangerouslySetInnerHTML={{ __html: reviewCard.back }} />
                  {reviewCard.backImage && (
                    <ZoomableImage src={reviewCard.backImage} alt="Back" className="card-image" />
                  )}
                  <div className="rating-controls">
                    <div className="rating-scale">
                      <span className="rating-label">Hard</span>
                      <input 
                        type="range"
                        min="0"
                        max="10"
                        value={rating}
                        onChange={(e) => setRating(parseInt(e.target.value))}
                        className="rating-slider"
                      />
                      <span className="rating-label">Easy</span>
                    </div>
                    <button onClick={handleReview} className="submit-button">Submit Review</button>
                  </div>
                </div>
              ) : (
                <button onClick={() => {
                  setShowBack(true);
                  stopTimer();
                }} 
                  className="show-answer">Show Answer</button>
              )}
            </div>
          ) : (
            <p>Loading card...</p>
          )}
        </div>
      )}
      
      {view === 'decks' && (
        <DeckView />
      )}
      
      {view === 'stats' && currentDeck && (
        <StatsView />
      )}

      {view === 'manage' && (
        <ManageView />
      )}

      {/* Timer modal for review session end notification */}
      {view === 'review' && isModalOpen && (
        <TimerModal onClose={() => setIsModalOpen(false)} />
      )}

      {/* Create deck modal */}
      {showCreateDeckModal && (
        <CreateDeckModal 
          onClose={() => setShowCreateDeckModal(false)}
          onSubmit={(name) => {
            handleCreateDeck(name);
            setShowCreateDeckModal(false);
          }}
        />
      )}

      <FooterMasthead />
    </div>
  );
}

export default App;
