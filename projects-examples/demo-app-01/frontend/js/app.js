// API Configuration
const API_BASE_URL = window.location.hostname === 'localhost' 
    ? 'http://localhost:5001' 
    : '/api';

// State
let currentSlide = 0;
let currentWelcomeSlide = 0;
let screenshots = [];
let welcomeSlides = 2; // Number of welcome slides

// Loading Management
const hideLoading = () => {
    const loading = document.querySelector('.loading');
    if (loading) {
        loading.classList.add('hidden');
    }
};

// Welcome Carousel Management
const initWelcomeCarousel = () => {
    const slides = document.querySelectorAll('.carousel-slide');
    const dots = document.querySelectorAll('.slider-dot');
    const prevBtn = document.getElementById('prevBtn');
    const nextBtn = document.getElementById('nextBtn');
    
    // Make sure we have the right number of slides
    welcomeSlides = slides.length;
    
    console.log("Initializing welcome carousel with " + welcomeSlides + " slides");
    
    // Set initial slide
    updateWelcomeCarousel();
    
    // Event listeners for controls
    if (prevBtn) {
        prevBtn.addEventListener('click', (e) => {
            e.preventDefault();
            console.log("Previous button clicked");
            currentWelcomeSlide = (currentWelcomeSlide - 1 + welcomeSlides) % welcomeSlides;
            updateWelcomeCarousel();
        });
    }
    
    if (nextBtn) {
        nextBtn.addEventListener('click', (e) => {
            e.preventDefault();
            console.log("Next button clicked");
            currentWelcomeSlide = (currentWelcomeSlide + 1) % welcomeSlides;
            updateWelcomeCarousel();
        });
    }
    
    // Dot clicks
    dots.forEach((dot, index) => {
        dot.addEventListener('click', () => {
            console.log("Dot " + index + " clicked");
            currentWelcomeSlide = index;
            updateWelcomeCarousel();
        });
    });
    
    // Auto advance every 8 seconds
    setInterval(() => {
        currentWelcomeSlide = (currentWelcomeSlide + 1) % welcomeSlides;
        updateWelcomeCarousel();
    }, 8000);
};

const updateWelcomeCarousel = () => {
    const slides = document.querySelectorAll('.carousel-slide');
    const dots = document.querySelectorAll('.slider-dot');
    
    console.log("Updating welcome carousel to slide " + currentWelcomeSlide);
    
    // Update slides
    slides.forEach((slide, index) => {
        if (index === currentWelcomeSlide) {
            slide.classList.add('active');
            slide.style.visibility = 'visible';
            slide.style.opacity = '1';
            slide.style.display = 'block';
            console.log("Showing slide " + index);
        } else {
            slide.classList.remove('active');
            slide.style.visibility = 'hidden';
            slide.style.opacity = '0';
            slide.style.display = 'none';
            console.log("Hiding slide " + index);
        }
    });
    
    // Update dots
    dots.forEach((dot, index) => {
        if (index === currentWelcomeSlide) {
            dot.classList.add('active');
        } else {
            dot.classList.remove('active');
        }
    });
};

// Smooth Scroll Navigation
document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function (e) {
        e.preventDefault();
        const target = document.querySelector(this.getAttribute('href'));
        if (target) {
            target.scrollIntoView({
                behavior: 'smooth',
                block: 'start'
            });
        }
    });
});

// Mobile Menu Toggle
const mobileMenuToggle = document.querySelector('.mobile-menu-toggle');
const navMenu = document.querySelector('.nav-menu');

if (mobileMenuToggle) {
    mobileMenuToggle.addEventListener('click', () => {
        navMenu.classList.toggle('active');
    });
}

// Active Navigation Link
const updateActiveNavLink = () => {
    const sections = document.querySelectorAll('section[id]');
    const navLinks = document.querySelectorAll('.nav-link');

    let current = '';
    sections.forEach(section => {
        const sectionTop = section.offsetTop;
        const sectionHeight = section.clientHeight;
        if (window.scrollY >= sectionTop - 100) {
            current = section.getAttribute('id');
        }
    });

    navLinks.forEach(link => {
        link.classList.remove('active');
        if (link.getAttribute('href') === `#${current}`) {
            link.classList.add('active');
        }
    });
};

window.addEventListener('scroll', updateActiveNavLink);

// Fetch and Display Features
async function loadFeatures() {
    try {
        const response = await fetch(`${API_BASE_URL}/api/features`);
        const data = await response.json();

        const featuresGrid = document.getElementById('features-grid');
        if (!featuresGrid) return;

        featuresGrid.innerHTML = data.features.map(feature => `
            <div class="feature-card">
                <div class="feature-icon">${feature.icon}</div>
                <h3 class="feature-title">${feature.name}</h3>
                <p class="feature-description">${feature.description}</p>
                <ul class="feature-benefits">
                    ${feature.benefits.map(benefit => `<li>${benefit}</li>`).join('')}
                </ul>
            </div>
        `).join('');
    } catch (error) {
        console.error('Error loading features:', error);
    }
}

// Fetch and Display Architecture
async function loadArchitecture() {
    try {
        const response = await fetch(`${API_BASE_URL}/api/architecture`);
        const data = await response.json();

        const componentsGrid = document.getElementById('components-grid');
        if (!componentsGrid) return;

        componentsGrid.innerHTML = data.components.map(component => `
            <div class="component-card">
                <div class="component-name">${component.name}</div>
                <div class="component-tech">${component.tech}</div>
                <p class="component-description">${component.description}</p>
                <ul class="component-responsibilities">
                    ${component.responsibilities.map(resp => `<li>${resp}</li>`).join('')}
                </ul>
            </div>
        `).join('');

        const dataFlow = document.getElementById('data-flow');
        if (dataFlow) {
            dataFlow.innerHTML = `
                <h3 class="flow-title">Data Flow</h3>
                <div class="flow-steps">
                    ${data.data_flow.map(step => `
                        <div class="flow-step">${step}</div>
                    `).join('')}
                </div>
            `;
        }
    } catch (error) {
        console.error('Error loading architecture:', error);
    }
}

// Fetch and Display Screenshots
async function loadScreenshots() {
    try {
        const response = await fetch(`${API_BASE_URL}/api/screenshots`);
        const data = await response.json();
        screenshots = data.screenshots;

        const sliderTrack = document.getElementById('slider-track');
        if (!sliderTrack) return;

        sliderTrack.innerHTML = screenshots.map(screenshot => `
            <div class="screenshot-slide">
                <div class="screenshot-image">
                    ${screenshot.placeholder}
                </div>
                <div class="screenshot-info">
                    <h3 class="screenshot-title">${screenshot.title}</h3>
                    <p class="screenshot-description">${screenshot.description}</p>
                </div>
            </div>
        `).join('');

        // Initialize slider dots
        const sliderDots = document.getElementById('slider-dots');
        if (sliderDots) {
            sliderDots.innerHTML = screenshots.map((_, index) => `
                <span class="slider-dot ${index === 0 ? 'active' : ''}" data-index="${index}"></span>
            `).join('');

            // Add click handlers to dots
            document.querySelectorAll('.slider-dot').forEach(dot => {
                dot.addEventListener('click', () => {
                    const index = parseInt(dot.getAttribute('data-index'));
                    goToSlide(index);
                });
            });
        }
    } catch (error) {
        console.error('Error loading screenshots:', error);
    }
}

// Slider Controls
function goToSlide(index) {
    const sliderTrack = document.getElementById('slider-track');
    if (!sliderTrack) return;

    currentSlide = index;
    const offset = -currentSlide * 100;
    sliderTrack.style.transform = `translateX(${offset}%)`;

    // Update dots
    document.querySelectorAll('.slider-dot').forEach((dot, i) => {
        dot.classList.toggle('active', i === currentSlide);
    });
}

function nextSlide() {
    const nextIndex = (currentSlide + 1) % screenshots.length;
    goToSlide(nextIndex);
}

function prevSlide() {
    const prevIndex = (currentSlide - 1 + screenshots.length) % screenshots.length;
    goToSlide(prevIndex);
}

// Add slider button event listeners
document.addEventListener('DOMContentLoaded', () => {
    const prevBtn = document.getElementById('slider-prev');
    const nextBtn = document.getElementById('slider-next');

    if (prevBtn) prevBtn.addEventListener('click', prevSlide);
    if (nextBtn) nextBtn.addEventListener('click', nextSlide);
});

// Fetch and Display Documentation
async function loadDocumentation() {
    try {
        const response = await fetch(`${API_BASE_URL}/api/documentation`);
        const data = await response.json();

        const docsGrid = document.getElementById('docs-grid');
        if (!docsGrid) return;

        docsGrid.innerHTML = Object.entries(data.documentation).map(([category, docs]) => `
            <div class="docs-category">
                <h3 class="docs-category-title">${docs.title}</h3>
                <ul class="docs-links">
                    ${docs.links.map(link => `
                        <li>
                            <a href="${link.url}" target="_blank" rel="noopener noreferrer">
                                ${link.title}
                            </a>
                        </li>
                    `).join('')}
                </ul>
            </div>
        `).join('');
    } catch (error) {
        console.error('Error loading documentation:', error);
    }
}

// Fetch and Display Contact Information
async function loadContacts() {
    try {
        const response = await fetch(`${API_BASE_URL}/api/contacts`);
        const data = await response.json();

        const contactGrid = document.getElementById('contact-grid');
        if (!contactGrid) return;

        contactGrid.innerHTML = data.contacts.map(contact => `
            <div class="contact-card">
                <div class="contact-role">${contact.role}</div>
                <div class="contact-name">${contact.name}</div>
                <div class="contact-info">
                    <a href="mailto:${contact.email}">${contact.email}</a>
                    ${contact.github ? `<a href="${contact.github}" target="_blank">GitHub Profile</a>` : ''}
                </div>
            </div>
        `).join('');
    } catch (error) {
        console.error('Error loading contacts:', error);
    }
}

// Update Hero Stats with Real Data
async function updateHeroStats() {
    try {
        const response = await fetch(`${API_BASE_URL}/api/info`);
        const data = await response.json();

        // You can update stats based on the API response
        // For now, we'll keep the hardcoded stats from HTML
        // But you could fetch metrics from your backend
    } catch (error) {
        console.error('Error loading hero stats:', error);
    }
}

// Initialize App
async function initializeApp() {
    try {
        // Initialize the welcome carousel
        initWelcomeCarousel();
        
        // Load all content in parallel
        await Promise.all([
            loadFeatures(),
            loadArchitecture(),
            loadScreenshots(),
            loadDocumentation(),
            loadContacts(),
            updateHeroStats()
        ]);

        // Hide loading screen
        hideLoading();
    } catch (error) {
        console.error('Error initializing app:', error);
        hideLoading();
    }
}

// Auto-play screenshots slider (optional)
let autoPlayInterval;

function startAutoPlay() {
    autoPlayInterval = setInterval(nextSlide, 5000); // Change slide every 5 seconds
}

function stopAutoPlay() {
    if (autoPlayInterval) {
        clearInterval(autoPlayInterval);
    }
}

// Pause auto-play when user interacts with slider
document.addEventListener('DOMContentLoaded', () => {
    const sliderContainer = document.querySelector('.screenshots-slider');
    if (sliderContainer) {
        sliderContainer.addEventListener('mouseenter', stopAutoPlay);
        sliderContainer.addEventListener('mouseleave', startAutoPlay);
    }
    
    // Start auto-play
    startAutoPlay();
});

// Error Handling for API failures
window.addEventListener('unhandledrejection', event => {
    console.error('Unhandled promise rejection:', event.reason);
    hideLoading();
});

// Initialize when DOM is ready
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initializeApp);
} else {
    initializeApp();
}

// Intersection Observer for scroll animations (optional enhancement)
const observerOptions = {
    threshold: 0.1,
    rootMargin: '0px 0px -100px 0px'
};

const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
        if (entry.isIntersecting) {
            entry.target.style.opacity = '1';
            entry.target.style.transform = 'translateY(0)';
        }
    });
}, observerOptions);

// Function to ensure carousel is correctly initialized
const initCarousel = () => {
    console.log("Initializing carousel");
    // Force correct display of initial slide
    const slides = document.querySelectorAll('.carousel-slide');
    slides.forEach((slide, index) => {
        if (index === 0) { // First slide
            slide.classList.add('active');
            slide.style.visibility = 'visible';
            slide.style.opacity = '1';
            slide.style.display = 'block';
        } else {
            slide.classList.remove('active');
            slide.style.visibility = 'hidden';
            slide.style.opacity = '0';
            slide.style.display = 'none';
        }
    });
    
    // Update dots
    const dots = document.querySelectorAll('.slider-dot');
    dots.forEach((dot, index) => {
        if (index === 0) {
            dot.classList.add('active');
        } else {
            dot.classList.remove('active');
        }
    });
};

// Observe elements for scroll animations
document.addEventListener('DOMContentLoaded', () => {
    // Initialize carousel explicitly
    initCarousel();
    initWelcomeCarousel();
    
    // Add direct event listeners to buttons as a backup
    document.getElementById('prevBtn')?.addEventListener('click', function(e) {
        e.preventDefault();
        console.log("Direct prev button click");
        currentWelcomeSlide = (currentWelcomeSlide - 1 + welcomeSlides) % welcomeSlides;
        updateWelcomeCarousel();
    });
    
    document.getElementById('nextBtn')?.addEventListener('click', function(e) {
        e.preventDefault();
        console.log("Direct next button click");
        currentWelcomeSlide = (currentWelcomeSlide + 1) % welcomeSlides;
        updateWelcomeCarousel();
    });
    
    // Set up animated elements
    const animatedElements = document.querySelectorAll('.feature-card, .component-card, .docs-category');
    animatedElements.forEach((el, index) => {
        el.style.setProperty('--card-index', index);
        el.style.opacity = '0';
        el.style.transform = 'translateY(20px)';
        el.style.transition = 'opacity 0.6s ease, transform 0.6s ease';
        observer.observe(el);
    });
    
    // Set up image modal functionality
    setupImageModal();
});

// Global function for inline click handlers
function showImageModal(imgElement) {
    console.log('showImageModal called directly with:', imgElement);
    const modal = document.getElementById('imageModal');
    const modalImg = document.getElementById('modalImage');
    
    // Set the image source
    modalImg.src = imgElement.src;
    
    // Make modal visible
    modal.style.cssText = 'display: block !important; opacity: 1 !important;';
    
    // Prevent scrolling
    document.body.style.overflow = 'hidden';
}

// Simple Image Modal Functionality
function setupImageModal() {
    // Get modal elements
    const modal = document.getElementById('imageModal');
    const modalImg = document.getElementById('modalImage');
    const closeBtn = document.querySelector('.close-modal');
    
    console.log('Setting up image modal with elements:', modal, modalImg, closeBtn);
    
    // Select all carousel images and architecture diagram
    // We need a careful selector to capture all clickable images
    const images = document.querySelectorAll('.slide-image img, img.arch-diagram, img.clickable-slide-image');
    console.log('Found clickable images:', images.length);
    
    // Add click handlers to each image
    images.forEach((img, index) => {
        img.style.cursor = 'pointer';
        console.log(`Image ${index}:`, img.src || img.getAttribute('src'));
        
        img.onclick = function(e) {
            console.log('Image clicked:', this.src || this.getAttribute('src'));
            e.preventDefault();
            e.stopPropagation(); // Prevent event bubbling
            
            // Set the image source before showing modal
            modalImg.src = this.src || this.getAttribute('src') || this.getAttribute('data-src');
            console.log('Setting modal image src to:', modalImg.src);
            
            // Force layout recalculation
            modalImg.offsetHeight;
            
            // Make modal visible with !important to override any potential conflicts
            modal.style.cssText = 'display: block !important; opacity: 1 !important;';
            
            // Prevent page scrolling when modal is open
            document.body.style.overflow = 'hidden';
            
            console.log('Modal should now be visible:', modal.style.display);
        };
    });
    
    // Function to close modal and restore scrolling
    function closeModal() {
        console.log('Closing modal');
        modal.style.cssText = 'display: none !important;';
        document.body.style.overflow = ''; // Restore scrolling
        console.log('Modal hidden, display is now:', modal.style.display);
    }
    
    // Close button functionality
    closeBtn.onclick = function(e) {
        e.preventDefault();
        e.stopPropagation();
        console.log('Close button clicked');
        closeModal();
    };
    
    // Close when clicking outside the image
    window.onclick = function(event) {
        if (event.target == modal) {
            console.log('Clicked outside the image');
            closeModal();
        }
    };
    
    // Close with Escape key
    document.addEventListener('keydown', function(event) {
        if (event.key === 'Escape' && modal.style.display === 'block') {
            closeModal();
        }
    });
    
    // Close with Escape key
    document.addEventListener('keydown', function(event) {
        if (event.key === 'Escape') {
            modal.style.display = 'none';
        }
    });
}
